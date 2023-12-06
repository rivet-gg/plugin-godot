@tool
extends VBoxContainer

var poll_timer: Timer
var rng := RandomNumberGenerator.new()

var server_pid = null

func _ready():
	poll_timer = Timer.new()
	poll_timer.autostart = true
	poll_timer.timeout.connect(_poll_server_status)
	add_child(poll_timer)


func exec_sh(script: String) -> int:
	return OS.create_process("sh", ["-c", script])
#	OS.create_process("CMD.exe", ["/C", script], output)


func run_rivet_command(args: PackedStringArray):
	var execute_id = rng.randi()
	return OS.create_process("rivet", args)


## Checks if the server process is still running.
func _poll_server_status():
	# Check if server still running
	if server_pid != null and !OS.is_process_running(server_pid):
		print("Server stopped")
		server_pid = null
	
	# Update stop button
	#$StopServer.disabled = server_pid == null
	#if server_pid != null:
		#$StartServer.text = "Restart Server"
		#$ServerPID.text = "Process ID: %s" % server_pid
		#$ServerPID.visible = true
	#else:
		#$StartServer.text = "Start Server"
		#$StopServer.text = "Stop Server"
		#$ServerPID.visible = false

func server_run_args() -> PackedStringArray:
	var project_path = ProjectSettings.globalize_path("res://")
	return ["--path", project_path, "--headless", "--", "--server"]

func start_server():
	if server_pid != null:
		stop_server()

	server_pid = OS.create_process(OS.get_executable_path(), server_run_args())

	_poll_server_status()


## Kills the server if running.
func stop_server():
	if server_pid != null:
		print("Stopped serer")
		OS.kill(server_pid)
		server_pid = null
		_poll_server_status()
	else:
		print("Server not running")


# MARK: UI
func _on_dashboard_pressed():
	run_rivet_command(["game", "dashboard"])


func _on_start_server_pressed():
	start_server()


func _on_stop_server_pressed():
	stop_server()


func _on_copy_command_pressed():
	var command = "%s %s" % [OS.get_executable_path(), " ".join(server_run_args())]
	DisplayServer.clipboard_set(command)


#func _on_edit_config_pressed():
#	print(ProjectSettings.globalize_path("res://rivet.version.toml"))
#	OS.shell_open("file://%s" % ProjectSettings.globalize_path("res://rivet.version.toml"))


#func _on_deploy_pressed():
#	deploy_pid = run_rivet_command(["deploy", "--namespace", "prod"])
#	_poll_server_status()

