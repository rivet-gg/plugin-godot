@tool extends Node

@onready var _task_logs: TaskLogs = %TaskLogs

signal state_change(running: bool)

# Config
var get_start_config: Callable
var get_stop_config: Callable
var init_message: String
var auto_start: bool = false

# State
var task
var _stop_task

func _ready():
	# Init
	_task_logs.add_log_line(init_message, TaskLogs.LogType.META)

	# Hook existing process (or start if auto-started)
	var config = await get_start_config.call("StartOrHook" if auto_start else "HookOnly")
	task = RivetTask.with_name_input(config.name, config.input)
	add_child(task)
	task.task_log.connect(_on_task_log)
	task.task_output.connect(_on_task_output)
	task.start()

	# Publish state change after defer so signals can be connected
	call_deferred("_on_state_change")

func start_task(restart: bool = true):
	# Do nothing if task already running
	if !restart && task != null:
		return

	# Kill old task
	stop_task()
	
	# Start new task
	var config = await get_start_config.call("StartOrHook")
	task = RivetTask.with_name_input(config.name, config.input)
	add_child(task)
	task.task_log.connect(_on_task_log)
	task.task_output.connect(_on_task_output)
	task.start()

	_on_state_change()

	_task_logs.add_log_line("Start", TaskLogs.LogType.META)

func stop_task():
	if task != null:
		# Abort running task
		task.kill()
		task = null

		_task_logs.add_log_line("Stop", TaskLogs.LogType.META)

		# Run stop task
		#
		# Save in global scope so it doesn't get dropped before getting called
		var stop_config = await get_stop_config.call()
		_stop_task = RivetTask.with_name_input(stop_config.name, stop_config.input)
		add_child(_stop_task)
		_stop_task.start()

		_on_state_change()

func _on_task_log(logs, type):
	var log_type
	if type == 0:
		log_type = TaskLogs.LogType.STDOUT
	elif type == 1:
		log_type = TaskLogs.LogType.STDERR
	else:
		RivetPluginBridge.warning("Unknown log type")
		return

	_task_logs.add_log_line(logs, log_type)

func _on_task_output(output):
	task = null
	_on_state_change()

	# Log output
	if "Ok" in output:
		_task_logs.add_log_line("Exited with exit code %s" % output["Ok"].exit_code, TaskLogs.LogType.META)
	elif "Err" in output:
		_task_logs.add_log_line("Task error: %s" % output["Err"], TaskLogs.LogType.META)
	
	# Restart if needed
	if auto_start:
		_task_logs.add_log_line("Restarting in 2 seconds", TaskLogs.LogType.META)
		await get_tree().create_timer(2.0).timeout
		start_task()

func _on_clear_logs_pressed():
	_task_logs.clear_logs()

func _on_state_change():
	state_change.emit(task != null)
