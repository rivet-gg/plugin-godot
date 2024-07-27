@tool extends Node

@onready var _start = %Start
@onready var _stop = %Stop
@onready var _restart = %Restart
@onready var _open_logs = %OpenLogs

@onready var _proc_manager: ProcessManager = %ProcessManager
@onready var _proc_logs: ProcessLogs = %ProcessLogs

func _ready():
	_proc_manager.get_process_command = _get_process_command 

func _get_process_command():
	var cli = RivetPluginBridge.get_plugin().cli
	return [cli.get_cli_path(), "sidekick", "backend-dev", "--no-color"]

func _on_process_manager_process_status_changed(status, _pid):
	_start.visible = status == ProcessManager.ProcessStatus.STOPPED
	_stop.visible = status == ProcessManager.ProcessStatus.RUNNING
	_restart.visible = status == ProcessManager.ProcessStatus.RUNNING
	_open_logs.visible = _proc_manager.logs_path != null

func _on_start_pressed():
	_proc_manager.start_process()

func _on_stop_pressed():
	_proc_manager.stop_process()

func _on_restart_pressed():
	_proc_manager.start_process()

func _on_clear_logs_pressed():
	_proc_logs.clear_logs()

func _on_open_logs_pressed():
	_proc_manager.open_logs_in_file_manager()
