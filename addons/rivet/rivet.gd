@tool extends EditorPlugin
class_name RivetPlugin
## Mainpoint for the Rivet editor plugin.

# MARK: Plugin
const AUTO_LOAD_RIVET_GLOBAL = "Rivet"
const RIVET_CLI_VERSION = "v2.0.0-rc.4"

const _RivetEditorSettings := preload("rivet_editor_settings.gd")
const _RivetGlobal := preload("rivet_global.gd")

var _dock: Control
var _game_server_panel: Control
var _backend_panel: Control
var _export_plugin: EditorExportPlugin
var _dialog: AcceptDialog

## The global singleton for the Rivet plugin, only available in the editor.
var global: _RivetGlobal
# var game_server_global: _RivetGlobal

func _init() -> void:
	name = "RivetPlugin"

func _enter_tree():
	# Add singleton
	add_autoload_singleton(AUTO_LOAD_RIVET_GLOBAL, "rivet_global.gd")

	# Global
	#
	# This gets added under Dock. This could be any node we own, it has no
	# specific behavior to the dock.
	global = _RivetGlobal.new()
	global.add_autoload.connect(_on_add_autoload)

	install_cli()

func install_cli():
	# If the CLI is already installed, skip to the rest of initialization
	if global.check_cli():
		_on_cli_installed()
	else:
		_dialog = AcceptDialog.new()
		_dialog.title = "Installing Rivet CLI"
		_dialog.dialog_text = "The Rivet CLI is being downloaded"
		_dialog.remove_button(_dialog.get_ok_button())
		
		add_child(_dialog)

		var http_request = HTTPRequest.new()
		var path = global.get_cli_path()

		DirAccess.make_dir_recursive_absolute(path[0])
		http_request.set_download_file(path[0].path_join(path[1]))
		http_request.request_completed.connect(_on_cli_download_completed)
		add_child(http_request)
		
		# Show the dialog
		_dialog.popup_centered()

		var target: String
		if OS.get_name() == "macOS":
			target = "rivet-cli-x86-mac"
		elif OS.get_name() == "Windows":
			target = "rivet-cli-x86-windows.exe"
		else:
			target = "rivet-cli-x86-linux"

		http_request.request("https://releases.rivet.gg/cli/%s/%s" % [RIVET_CLI_VERSION, target])

func _on_cli_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	# # If we aren't on Windows, set the executable bit
	if OS.get_name() != "Windows":
		var path = global.get_cli_path()
		var command = "chmod +x " + path[0].path_join(path[1])
		OS.execute("/bin/sh", ["-c", command])

	_on_cli_installed()

func _on_cli_installed():
	# Dock
	_dock = preload("ui/dock/dock.tscn").instantiate()
	_dock.add_child(global)

	add_control_to_dock(DOCK_SLOT_LEFT_BR, _dock)

	# Game server
	_game_server_panel = preload("ui/task_panel/task_panel.tscn").instantiate()
	_game_server_panel.init_message = "Open \"Develop\" and press \"Start\" to start game server."
	_game_server_panel.get_task_config = func():
		var project_path = ProjectSettings.globalize_path("res://")
		return {
			"name": "exec_command",
			"input": {
				"cwd": project_path,
				"cmd": OS.get_executable_path(),
				"args": ["--project", project_path, "--headless", "--", "--server"]
			}
		}
	add_control_to_bottom_panel(_game_server_panel, "Game Server")

	# Close the dialog if it exists
	if _dialog:
		remove_child(_dialog)
		_dialog.free()

	# Backend
	_backend_panel = preload("ui/task_panel/task_panel.tscn").instantiate()
	_backend_panel.auto_restart = true
	_backend_panel.init_message = "Auto-started by Rivet plugin."
	_backend_panel.get_task_config = func():
		# Choose port to run on. This is to avoid potential conflicts with
		# multiple projects running at the same time.
		var choose_res = await global.run_toolchain_task("backend_choose_local_port")
		global.local_backend_port = choose_res.port

		# Run project
		var project_path = ProjectSettings.globalize_path("res://")
		return {
			"name": "backend_dev",
			"input": {
				"port": choose_res.port,
				"cwd": project_path,
			}
		}
	add_control_to_bottom_panel(_backend_panel, "Backend")

	# Add export plugin
	_export_plugin = preload("rivet_export_plugin.gd").new()
	add_export_plugin(_export_plugin)

	# Settings
	_RivetEditorSettings.set_defaults()

	global.plugin_nodes = [_dock, _game_server_panel, _backend_panel]

	# Signals
	global.start_game_server.connect(func(): _game_server_panel.start_task())
	global.stop_game_server.connect(func(): _game_server_panel.stop_task())
	global.focus_game_server.connect(_on_focus_game_server)
	_game_server_panel.state_change.connect(func(running): global.game_server_state_change.emit(running))

	global.start_backend.connect(func(): _backend_panel.start_task())
	global.stop_backend.connect(func(): _backend_panel.stop_task())
	global.focus_backend.connect(_on_focus_backend)
	_backend_panel.state_change.connect(func(running): global.backend_state_change.emit(running))

	# Start backend
	_backend_panel.start_task.call_deferred()
	
func _exit_tree():
	# Stop processes
	_game_server_panel.stop_task()
	_backend_panel.stop_task()

	# Remove singleton
	remove_autoload_singleton(AUTO_LOAD_RIVET_GLOBAL)

	# Remove export plugin
	remove_export_plugin(_export_plugin)
	_export_plugin = null
	
	# Remove dock
	remove_control_from_docks(_dock)
	_dock.free()

	# Remove game server
	remove_control_from_bottom_panel(_game_server_panel)
	_game_server_panel.free()

	# Remove backend
	remove_control_from_bottom_panel(_backend_panel)
	_backend_panel.free()

func _on_add_autoload(name: String, path: String):
	add_autoload_singleton(name, path)

func _on_focus_game_server():
	make_bottom_panel_item_visible(_game_server_panel)

func _on_focus_backend():
	make_bottom_panel_item_visible(_backend_panel)
