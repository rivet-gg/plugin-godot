extends RefCounted
class_name RivetTask
## Handles running subprocess & piping logs.

enum LogType { STDOUT, STDERR }

const POLL_LOGS_INTERVAL = 0.25
const RIVET_EXECUTOR = "cli"

## Task logged something
signal task_log(logs: String, type: LogType)

## Called on success
signal task_ok(ok: Variant)

## Called on failure
signal task_error(error: Variant)

## Called on either OK or error.
signal task_output(error: Variant)

# Config
var _name: String
var _input: Variant

# State
var is_running = true
var state_files
var _thread
var _log_file
var _log_last_position

func _init(name: String, input: Variant):
	if name == null or input == null:
		push_error("RivetTask initiated without required args")
		return

	self._name = name
	self._input = input

	# Generate state to coordinate with task
	state_files = _gen_state_files_dir()
	if state_files == null:
		return

	# Run command
	var run_config_json = JSON.stringify({
		"abort_path": state_files.abort,
		"output_path": state_files.output,
	})
	var input_json = JSON.stringify(_input)

	_thread = Thread.new()
	_thread.start(func():
		var output = _run(run_config_json, input_json)
		call_deferred("_on_finish")
		return output
	)

	# Tail logs
	_tail_logs(state_files.output)

func _run(run_config_json: String, input_json: String):
	if RIVET_EXECUTOR == "cli":
		var cli_path: String
		match OS.get_name():
			"Windows":
				cli_path = "addons/rivet/cli/rivet_windows.exe"
			"macOS":
				cli_path = "addons/rivet/cli/rivet_x86_apple"
			"Linux":
				cli_path = "addons/rivet/cli/rivet_linux"
			_:
				push_error("Unsupported operating system")
				return

		var args = [
			"task",
			"run",
			"--name",
			self._name.c_escape(),
			"--run-config",
			run_config_json.c_escape(),
			"--input",
			input_json.c_escape(),
		]
		
		var output = []
		OS.execute(cli_path, args, output, true)

		return output

func _on_finish():
	# This will not block because this event is emitted after the task is cancelled
	var output_json = _thread.wait_to_finish()
	_finish_logs()

	is_running = false

	var output = JSON.parse_string(output_json[0].c_unescape())

	task_output.emit(output)
	if "Ok" in output:
		RivetPluginBridge.log("[%s] Success: %s" % [_name, output["Ok"]])
		task_ok.emit(output["Ok"])
	else:
		RivetPluginBridge.error("[%s] Error: %s" % [_name, output["Err"]])
		task_error.emit(output["Err"])

func _on_killed():
	var error = "Process killed"
	task_output.emit({ "Err": error })
	task_error.emit(error)

func kill():
	if not is_running:
		return

	RivetPluginBridge.log("Aborting process")

	# Write to abort file
	_touch_file(state_files.abort)

## Generates a temporary directory holding the state of this process. Used for
#communication between the task and Godot.
func _gen_state_files_dir():
	var temp_base_dir = OS.get_user_data_dir().path_join("tmp")
	var unique_id = floor(Time.get_unix_time_from_system())
	var temp_dir_path = temp_base_dir.path_join("task_%s_%s" % [_name, unique_id])
	
	var dir = DirAccess.open("user://")
	var error = dir.make_dir_recursive(temp_dir_path)
	
	if error == OK:
		var temp_abort_path = temp_dir_path.path_join("abort")
		var temp_output_path = temp_dir_path.path_join("output")
		_touch_file(temp_output_path)

		return {
			"base": temp_dir_path,
			"abort": temp_abort_path,
			"output": temp_output_path,
		}
	else:
		RivetPluginBridge.error("Failed to create temporary directory: %s" % error)
		return null

func _touch_file(path: String):
	_log_file = FileAccess.open(path, FileAccess.WRITE)
	_log_file.close()

## Tail a file and print it to the console in realtime.
func _tail_logs(path: String):
	# Open file
	_log_file = FileAccess.open(path, FileAccess.READ)
	if _log_file == null:
		RivetPluginBridge.error("Failed to open file: %s" % path)
		return
	
	# Poll file
	_log_last_position = 0
	while true:
		# Stop polling file if process stopped. Do this after reading the end of
		# the file before the process exited.
		if not is_running:
			break

		# Read logs
		_read_log_tail()
		
		# Wait for next tick
		await Engine.get_main_loop().create_timer(POLL_LOGS_INTERVAL).timeout

## Read the end of the logs. Runs on task exit in order to finish printing the
## file.
func _finish_logs():
	_read_log_tail()
	_log_file.close()

## Reads the end of the logs.
func _read_log_tail():
	var current_position = _log_file.get_length()
	if current_position > _log_last_position:
		# Read new text
		_log_file.seek(_log_last_position)
		var new_content = _log_file.get_buffer(current_position - _log_last_position).get_string_from_utf8()
		_log_last_position = current_position

		# Parse lines
		var lines = new_content.split("\n", false)
		for line in lines:
			var parsed = JSON.parse_string(line)
			if parsed == null:
				print('Failed to parse: %s' % line)
				continue
			elif "Stdout" in parsed:
				task_log.emit(parsed["Stdout"], LogType.STDOUT)
			elif "Stderr" in parsed:
				task_log.emit(parsed["Stderr"], LogType.STDERR)

