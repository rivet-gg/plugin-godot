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
var is_killed = false
var state_files
var _log_result  # Will be passed when receives `output` event from log to be passed to task_output later
var _task_handle = null

func _init(name: String, input: Variant):
	if name == null or input == null:
		RivetPluginBridge.error("RivetTask initiated without required args")
		return

	self._name = name
	self._input = input

	var input_json = JSON.stringify(_input)

	RivetPluginBridge.log("[%s] Request: %s" % [_name, input_json])
	var toolchain = RivetToolchain.new()
	WorkerThreadPool.add_task(_run.bind(toolchain, name, input_json))

func _run(toolchain: RivetToolchain, name: String, input_json: String):
	toolchain.run_task(name, input_json, _on_start, _on_output_event)
	call_deferred("_on_finish")

func _on_start(task_handle):
	self._task_handle = task_handle

func _on_finish():
	is_running = false

	var output_result = null
	if is_killed:
		output_result = { "Err": "Task killed" }
	else:
		if _log_result == null:
			RivetPluginBridge.error("Received no output from task")
			return

		output_result = _log_result["result"]

	task_output.emit(output_result)
	if "Ok" in output_result:
		RivetPluginBridge.log("[%s] Success: %s" % [_name, output_result["Ok"]])
		task_ok.emit(output_result["Ok"])
	else:
		RivetPluginBridge.error("[%s] Error: %s" % [_name, output_result["Err"]])
		task_error.emit(output_result["Err"])

func _on_output_event(event_json):
	call_deferred("_handle_on_output_event", event_json)

func _handle_on_output_event(event_json):
	var event = JSON.parse_string(event_json)
	if "log" in event:
		# Emit signal on main thread
		call_deferred('_on_log_event', event)
	elif "result" in event:
		_log_result = event["result"]
	elif "port_update" in event:
		var plugin = RivetPluginBridge.get_plugin()
		plugin.local_backend_port = event["port_update"].backend_port
		plugin.local_editor_port = event["port_update"].editor_port

		RivetPluginBridge.instance.save_configuration()
		RivetPluginBridge.log("Port update: backend=%s editor=%s" % [plugin.local_backend_port, plugin.local_editor_port])
	else:
		RivetPluginBridge.warning("Unknown event %s" % event_json)

func _on_log_event(event):
	task_log.emit(event["log"], LogType.STDOUT)

func kill():
	if not is_running or is_killed:
		return

	is_killed = true

	if _task_handle != null:
		RivetPluginBridge.log("Killing task")
		_task_handle.abort()
	else:
		RivetPluginBridge.warning("No task handle")
