@tool extends Node

const _RivetTask = preload("../rivet_task.gd")

@onready var _start = %Start
@onready var _stop = %Stop
@onready var _restart = %Restart

@onready var _task_logs: TaskLogs = %TaskLogs

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

	_update_ui()

	_task_logs.add_log_line("Start", TaskLogs.LogType.META)

func stop_task():
	if task != null:
		task.kill()
		task = null

		_task_logs.add_log_line("Stop", TaskLogs.LogType.META)

		_update_ui()

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
	_update_ui()

	if "Ok" in output:
		_task_logs.add_log_line("Exited with exit code %s" % output["Ok"].exit_code, TaskLogs.LogType.META)
	elif "Err" in output:
		_task_logs.add_log_line("Task error: %s" % output["Err"], TaskLogs.LogType.META)

func _on_start_pressed():
	start_task()

func _on_stop_pressed():
	stop_task()

func _on_restart_pressed():
	start_task()

func _on_clear_logs_pressed():
	_task_logs.clear_logs()

func _update_ui():
	var running = task != null
	_start.visible = !running
	_stop.visible = running
	_restart.visible = running
