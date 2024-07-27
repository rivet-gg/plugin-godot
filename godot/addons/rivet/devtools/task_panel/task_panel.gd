@tool extends Node

const _RivetTask = preload("../rivet_task.gd")

@onready var _task_logs: TaskLogs = %TaskLogs

signal state_change(running: bool)

# Config
var get_task_config: Callable
var init_message: String

# State
var task

func _ready():
	_task_logs.add_log_line(init_message, TaskLogs.LogType.META)

func start_task():
	stop_task()
	
	var config = get_task_config.call()
	task = _RivetTask.new(config.name, config.input)
	task.task_log.connect(_on_task_log)
	task.task_output.connect(_on_task_output)

	_on_state_change()

	_task_logs.add_log_line("Start", TaskLogs.LogType.META)

func stop_task():
	if task != null:
		task.kill()
		task = null

		_task_logs.add_log_line("Stop", TaskLogs.LogType.META)

		_on_state_change()

func _on_task_log(logs, type):
	var log_type
	if type == RivetTask.LogType.STDOUT:
		log_type = TaskLogs.LogType.STDOUT
	elif type == RivetTask.LogType.STDERR:
		log_type = TaskLogs.LogType.STDERR
	else:
		RivetPluginBridge.warning("Unknown log type")
		return

	_task_logs.add_log_line(logs, log_type)

func _on_task_output(output):
	task = null
	_on_state_change()

	if "Ok" in output:
		_task_logs.add_log_line("Exited with exit code %s" % output["Ok"].exit_code, TaskLogs.LogType.META)
	elif "Err" in output:
		_task_logs.add_log_line("Task error: %s" % output["Err"], TaskLogs.LogType.META)

func _on_clear_logs_pressed():
	_task_logs.clear_logs()

func _on_state_change():
	state_change.emit(task != null)
