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
var _restart_timer: Timer

func _ready():
	# Init
	_task_logs.add_log_line(init_message, TaskLogs.LogType.META)

	if RivetPluginBridge.is_running_as_plugin(self):
		_restart_timer = Timer.new()
		_restart_timer.wait_time = 2.0
		_restart_timer.one_shot = true
		_restart_timer.timeout.connect(_on_restart_delay)
		add_child(_restart_timer)

		# Start process
		if auto_start:
			var config = await get_start_config.call()
			task = RivetTask.with_name_input(config.name, config.input)
			add_child(task)
			task.task_log.connect(_on_task_log.bind(task))
			task.task_output.connect(_on_task_output.bind(task))
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
	var config = await get_start_config.call()
	task = RivetTask.with_name_input(config.name, config.input)
	add_child(task)
	task.task_log.connect(_on_task_log.bind(task))
	task.task_output.connect(_on_task_output.bind(task))
	task.start()

	_on_state_change()

	_task_logs.add_log_line("Start", TaskLogs.LogType.META)

func stop_task():
	if task != null:
		# Abort running task
		var local_task = task
		task = null
		local_task.kill()

		_task_logs.add_log_line("Stop", TaskLogs.LogType.META)

		# Run stop task
		#
		# Save in global scope so it doesn't get dropped before getting called
		var stop_config = await get_stop_config.call()
		_stop_task = RivetTask.with_name_input(stop_config.name, stop_config.input)
		add_child(_stop_task)
		_stop_task.start()

		_on_state_change()

func _on_task_log(logs, type, source_task):
	if source_task != task:
		return

	var log_type
	if type == 0:
		log_type = TaskLogs.LogType.STDOUT
	elif type == 1:
		log_type = TaskLogs.LogType.STDERR
	else:
		RivetPluginBridge.warning("Unknown log type")
		return

	_task_logs.add_log_line(logs, log_type)

func _on_task_output(output, source_task):
	if source_task != task:
		return

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
		_restart_timer.start()

func _on_clear_logs_pressed():
	_task_logs.clear_logs()

func _on_state_change():
	state_change.emit(task != null)

func _on_restart_delay():
	start_task()
