@tool extends Node
class_name ProcessManager
## Handles running subprocess & piping logs.

enum ProcessStatus { STOPPED, RUNNING }

const POLL_LOGS_INTERVAL = 0.25

signal process_status_changed(status: ProcessStatus, pid: int)

## Node to write logs to.
@export var logs: ProcessLogs

## Command to run for the process.
var get_process_command: Callable
var process_poll_timer: Timer
var process_status: ProcessStatus = ProcessStatus.STOPPED:
	set(new_value):
		if new_value == process_status:
			return
		process_status = new_value
		process_poll_timer.paused = new_value == ProcessStatus.STOPPED
		process_status_changed.emit(new_value, process_pid)

var process_pid: int = -1

## Path to dir where the logs live.
var logs_path: String

var _strip_ansi_regex: RegEx

func _ready():
	_strip_ansi_regex = RegEx.new()
	_strip_ansi_regex.compile("\\x1b\\[[0-9;]*[a-zA-Z]")

	process_poll_timer = Timer.new()
	process_poll_timer.wait_time = 0.5
	process_poll_timer.paused = true
	process_poll_timer.autostart = true
	process_poll_timer.timeout.connect(_poll_status)
	add_child(process_poll_timer)

func _exit_tree():
	# Ensure the process is properly stopped
	stop_process()

func start_process():
	if process_status == ProcessStatus.RUNNING:
		stop_process()

	var process_command = get_process_command.call()

	# Generate logs dir
	var logs_dir = _gen_temp_logs_dir("logs")
	logs_path = logs_dir.base

	# Run the command and get the PID. Use this instead of OS.execute since this
	# allows us to pipe logs to files & handle graceful kill.
	var cli = RivetPluginBridge.get_plugin().cli
	var cmd = ["sidekick", "exec-command", "--stdout", logs_dir.stdout, "--stderr", logs_dir.stderr, "--"] + process_command
	process_pid = cli.run_with_pid(cmd)

	if process_pid != -1:
		process_status = ProcessStatus.RUNNING
		logs.add_log_line("Started process %s" % process_pid, ProcessLogs.LogType.META)

		_tail_file(process_pid, logs_dir.stdout, ProcessLogs.LogType.STDOUT)
		_tail_file(process_pid, logs_dir.stderr, ProcessLogs.LogType.STDERR)
	else:
		logs.add_log_line("Failed to start process", ProcessLogs.LogType.STDERR)

func stop_process():
	if process_status == ProcessStatus.RUNNING:
		logs.add_log_line("Stopping process %s" % process_pid, ProcessLogs.LogType.META)
		var kill_pid = process_pid
		process_pid = -1
		process_status = ProcessStatus.STOPPED

		# Gracefully kill the process. Don't use OS.kill since this sends a
		# SIGKILL instead of a SIGINT.
		RivetPluginBridge.get_plugin().cli.run(["sidekick", "kill-process", "--pid", kill_pid])

func _poll_status():
	# Check if the process is still running
	if process_pid != -1 and !OS.is_process_running(process_pid):
		_on_process_finished()

func _on_process_finished():
	logs.add_log_line("Process %s finished" % process_pid, ProcessLogs.LogType.META)
	process_status = ProcessStatus.STOPPED
	process_pid = -1

## Tail a file and print it to the cosole in realtime.
##
## log_pid = the pid of the process being logged
## path = path to the log t poll
## log_type = how to print the logs out
func _tail_file(log_pid: int, path: String, log_type: ProcessLogs.LogType):
	# Open file
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		RivetPluginBridge.error("Failed to open file: %s" % path)
		return
	
	# Poll file
	var last_position = 0
	while true:
		# Stop polling file if PID no longer running
		if process_pid != log_pid:
			break

		var current_position = file.get_length()
		if current_position > last_position:
			# Read new text
			file.seek(last_position)
			last_position = current_position
			var new_content = file.get_as_text()

			# Strip ansi codes
			new_content = _strip_ansi_regex.sub(new_content, "", true)

			# Log text
			logs.add_log_line(new_content, log_type)
		
		# Wait for next tick
		await get_tree().create_timer(POLL_LOGS_INTERVAL).timeout

func _gen_temp_logs_dir(name: String):
	var temp_base_dir = OS.get_user_data_dir().path_join("tmp")
	var unique_id = floor(Time.get_unix_time_from_system())
	var temp_dir_path = temp_base_dir.path_join("%s_%s" % [name, unique_id])
	
	var dir = DirAccess.open("user://")
	var error = dir.make_dir_recursive(temp_dir_path)
	
	if error == OK:
		var temp_stdout_path = temp_dir_path.path_join("stdout.txt")
		var temp_stderr_path = temp_dir_path.path_join("stderr.txt")
		_touch_file(temp_stdout_path)
		_touch_file(temp_stderr_path)

		return {
			"base": temp_dir_path,
			"stdout": temp_stdout_path,
			"stderr": temp_stderr_path,
		}
	else:
		RivetPluginBridge.error("Failed to create temporary directory: %s" % error)
		return ""

func _touch_file(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.close()
	
func open_logs_in_file_manager():
	if logs_path != null:
		OS.shell_show_in_file_manager(logs_path)
