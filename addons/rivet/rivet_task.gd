extends RefCounted
class_name RivetTask
## Handles running subprocess & piping logs.

const _RivetCliManager = preload("rivet_cli_manager.gd")

enum LogType { STDOUT, STDERR }

const POLL_LOGS_INTERVAL = 0.25

const EXECUTE_METHOD = "ffi"

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
var _log_last_position = 0
var _log_output  # Will be passed when receives `output` event from log to be passed to task_output later

func _init(name: String, input: Variant):
	if name == null or input == null:
		RivetPluginBridge.error("RivetTask initiated without required args")
		return

	self._name = name
	self._input = input

	# Generate state to coordinate with task
	state_files = _gen_state_files_dir()
	if state_files == null:
		return

	if EXECUTE_METHOD == "cli":
		# Open log file
		_log_file = FileAccess.open(state_files.output, FileAccess.READ)
		if _log_file == null:
			RivetPluginBridge.error("Failed to open file: %s" % state_files.output)
			return

	# Run command
	var run_config_json = JSON.stringify({
		"abort_path": state_files.abort,
		"output_path": state_files.output,
	})
	var input_json = JSON.stringify(_input)

	WorkerThreadPool.add_task(_run.bind(name, run_config_json, input_json))

func _run(name: String, run_config_json: String, input_json: String):
	
	if EXECUTE_METHOD == "ffi":
		var toolchain = RivetToolchain.new()
		toolchain.run_task(run_config_json, _name, input_json, _on_output_event)
	elif EXECUTE_METHOD == "cli":
		# c_escape required for passing JSON-encoded strings with weird charagers to args
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

		# Run command
		var output = []
		var exit_code = OS.execute(_RivetCliManager.get_bin_path(), args, output, true)
		if exit_code != 0:
			RivetPluginBridge.error("Task execute failed with exit code %d:\n%s" % [exit_code, output])
			return
	else:
		RivetPluginBridge.error("Unreachable")

	call_deferred("_on_finish")

func _on_finish():
	_finish_logs()

	is_running = false

	if _log_output == null:
		RivetPluginBridge.error("Received no output from task")
		return

	var output_result = _log_output["result"]

	task_output.emit(output_result)
	if "Ok" in output_result:
		RivetPluginBridge.log("[%s] Success: %s" % [_name, output_result["Ok"]])
		task_ok.emit(output_result["Ok"])
	else:
		RivetPluginBridge.error("[%s] Error: %s" % [_name, output_result["Err"]])
		task_error.emit(output_result["Err"])

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
	# Poll file
	#
	# Stop polling file if process stopped. _finish_logs is responsible for
	# reading the end of the file.
	while is_running:
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
			_on_output_event(parsed)

func _on_output_event(event):
	elif "stdout" in event:
		task_log.emit(event["stdout"], LogType.STDOUT)
	elif "stderr" in event:
		task_log.emit(event["stderr"], LogType.STDERR)
	elif "output" in event:
		_log_output = event["output"]
