extends RefCounted
class_name RivetTask
## Handles running subprocess & piping logs.

const _RivetCliManager = preload("rivet_cli_manager.gd")

enum LogType { STDOUT, STDERR }

const POLL_LOGS_INTERVAL = 0.25

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

	WorkerThreadPool.add_task(_run.bind(name, run_config_json, input_json))

	# Tail logs
	_tail_logs(state_files.output)

func _run(name: String, run_config_json: String, input_json: String):
	var args = [
		"task",
		"run",
		"--name",
		name.c_escape(),
		"--run-config",
		run_config_json.c_escape(),
		"--input",
		input_json.c_escape(),
	]
	
	var output = []
	OS.execute(_RivetCliManager.get_bin_path(), args, output, true)

	call_deferred("_on_finish", output)

func _on_finish(output_json):
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
	# We can't do this on Windows for now because of how files are opened and
	# written to.
	# https://github.com/rivet-gg/plugin-godot/issues/184
	if OS.get_name() == "Windows":
		return

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
