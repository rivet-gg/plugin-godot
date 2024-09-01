extends RefCounted
class_name RivetTask
## Handles running subprocess & piping logs.

enum LogType { STDOUT, STDERR }

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
var _log_result  # Will be passed when receives `output` event from log to be passed to task_output later

func _init(name: String, input: Variant):
	if name == null or input == null:
		RivetPluginBridge.error("RivetTask initiated without required args")
		return

	self._name = name
	self._input = input

	var input_json = JSON.stringify(_input)

	var toolchain = RivetToolchain.new()
	WorkerThreadPool.add_task(_run.bind(toolchain, name, input_json))

func _run(toolchain: RivetToolchain, name: String, input_json: String):
	toolchain.run_task(name, input_json, _on_output_event)
	call_deferred("_on_finish")

func _on_finish():
	is_running = false

	if _log_result == null:
		RivetPluginBridge.error("Received no output from task")
		return

	var output_result = _log_result["result"]

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
	RivetPluginBridge.error("TODO: unimplemented")

func _on_output_event(event_json):
	var event = JSON.parse_string(event_json)
	if "log" in event:
		# Emit signal on main thread
		call_deferred('_on_log_event', event)
	elif "result" in event:
		_log_result = event["result"]

func _on_log_event(event):
	task_log.emit(event["log"], LogType.STDOUT)
