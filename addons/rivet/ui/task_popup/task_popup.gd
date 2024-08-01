@tool extends Window
class_name TaskPopup

const _RivetTask = preload("../../rivet_task.gd")

signal task_output(output: Variant)

@onready var _proc_logs: TaskLogs = %TaskLogs

# Config
var task_name: String
var task_input: Variant

# State
var task: _RivetTask

@onready var _done_button: Button = %Done

func _ready():
	if not RivetPluginBridge.get_plugin().is_running_as_plugin(self):
		return

	task = _RivetTask.new(task_name, task_input)
	task.task_log.connect(_on_task_log)
	task.task_output.connect(_on_task_output)

	_update_ui()

	_proc_logs.add_log_line("Started task", TaskLogs.LogType.META)

	%Done.grab_focus()

func _stop_process():
	if task == null:
		return

	task.kill()

	_proc_logs.add_log_line("Stopped task", TaskLogs.LogType.META)

	_update_ui()

func _on_task_log(logs, type):
	var log_type
	if type == _RivetTask.LogType.STDOUT:
		log_type = TaskLogs.LogType.STDOUT
	elif type == _RivetTask.LogType.STDERR:
		log_type = TaskLogs.LogType.STDERR
	else:
		RivetPluginBridge.warning("Unknown log type")
		return

	_proc_logs.add_log_line(logs, log_type)

func _on_task_output(output):
	_update_ui()

	_proc_logs.add_log_line("Exited with %s" % output, TaskLogs.LogType.META)

	task_output.emit(output)

	if "Err" in output:
		_proc_logs.add_log_line(output["Err"], TaskLogs.LogType.STDERR)

func _on_done_pressed():
	_stop_process()
	hide()

func _on_close_requested():
	_stop_process()
	hide()

func _update_ui():
	var running = task.is_running
	_done_button.text = "Cancel" if running else "Done"


