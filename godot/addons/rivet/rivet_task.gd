extends RefCounted
class_name RivetTask
## Handles running subprocess & piping logs.

const _RivetThread = preload("rivet_thread.gd")

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

var _name: String
var _input: Variant

# State
var is_running = true
var thread
var state_files

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
	#
	# We need a dedicated RivetToolchain instance for each instance since we
	# can have concurrent calls to nodes.
	#
	# We ser/de JSON on the main thread because of Godot's multithreading
	# constraints.
	var toolchain = RivetToolchain.new()
	var run_config = JSON.stringify({
		"abort_path": state_files.abort,
		"output_path": state_files.output,
	})
	var input_json = JSON.stringify(_input)
	var output = _RivetThread.new(_run.bind(toolchain, run_config, input_json))
	output.finished.connect(_on_finish)
	output.killed.connect(_on_finish)

	# Tail logs
	_tail_logs(state_files.output)

func _run(toolchain: RivetToolchain, run_config_json: String, input_json: String):
	return toolchain.run_task(run_config_json, _name, input_json)

func _on_finish(output_json: String):
	is_running = false

	var output = JSON.parse_string(output_json)

	task_output.emit(output)
	if "Ok" in output:
		RivetPluginBridge.log("Task OK: %s" % output["Ok"])
		task_ok.emit(output["Ok"])
	else:
		RivetPluginBridge.error("Task error: %s" % output["Err"])
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
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.close()

## Tail a file and print it to the console in realtime.
func _tail_logs(path: String):
	var log_type = LogType.STDOUT

	# Open file
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		RivetPluginBridge.error("Failed to open file: %s" % path)
		return
	
	# Poll file
	var last_position = 0
	while true:
		var current_position = file.get_length()
		if current_position > last_position:
			# Read new text
			file.seek(last_position)
			var new_content = file.get_buffer(current_position - last_position).get_string_from_utf8()
			last_position = current_position

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

		# Stop polling file if process stopped. Do this after reading the end of
		# the file before the process exited.
		if not is_running:
			break
		
		# Wait for next tick
		await Engine.get_main_loop().create_timer(POLL_LOGS_INTERVAL).timeout
