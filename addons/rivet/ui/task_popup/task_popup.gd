@tool extends Window
class_name TaskPopup

signal task_output(output: Variant)

@onready var _proc_logs: TaskLogs = %TaskLogs

# Config
var task_name: String
var task_input: Variant
var ok_message: String

# State
var task: RivetTask
var is_running = true

@onready var _done_button: Button = %Done

func _ready():
	if not RivetPluginBridge.is_running_as_plugin(self):
		return

	task = RivetTask.with_name_input(task_name, task_input)
	add_child(task)
	task.task_log.connect(_on_task_log)
	task.task_output.connect(_on_task_output)
	task.start()

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
	if type == 0:
		log_type = TaskLogs.LogType.STDOUT
	elif type == 1:
		log_type = TaskLogs.LogType.STDERR
	else:
		RivetPluginBridge.warning("Unknown log type")
		return

	_proc_logs.add_log_line(logs, log_type)

func _on_task_output(output):
	is_running = false
	_update_ui()

	_proc_logs.add_log_line("Exited with %s" % output, TaskLogs.LogType.META)

	task_output.emit(output)

	if "Ok" in output:
		if ok_message != null:
			_proc_logs.add_log_line(ok_message, TaskLogs.LogType.STDOUT)
	elif "Err" in output:
		_proc_logs.add_log_line(output["Err"], TaskLogs.LogType.STDERR)

func _on_done_pressed():
	_stop_process()
	hide()

func _on_close_requested():
	_stop_process()
	hide()

func _update_ui():
	_done_button.text = "Cancel" if is_running else "Done"


