@tool extends EditorPlugin
class_name RivetPlugin
## Mainpoint for the Rivet editor plugin.

# MARK: Plugin
const _RivetEditorSettings := preload("rivet_editor_settings.gd")
const _RivetGlobal := preload("rivet_global.gd")

var _dock: RivetDock
var _game_server_panel: Control
var _backend_panel: Control
var _export_plugin: EditorExportPlugin
var _dialog: AcceptDialog

var dock: RivetDock:
	get:
		return _dock

## The global singleton for the Rivet plugin, only available in the editor.
var global: _RivetGlobal

func _init() -> void:
	name = "RivetPlugin"

func _enter_tree():
	# Setup runtime
	RivetToolchain.setup()

	# Global
	#
	# This gets added under Dock. This could be any node we own, it has no
	# specific behavior to the dock.
	global = _RivetGlobal.new()
	global.add_autoload.connect(_on_add_autoload)  # Allow calling the plugin from global

	# Dock
	_dock = preload("ui/dock/dock.tscn").instantiate()
	_dock.add_child(global)

	add_control_to_dock(DOCK_SLOT_LEFT_BR, _dock)

	# Game server
	_game_server_panel = preload("ui/task_panel/task_panel.tscn").instantiate()
	_game_server_panel.init_message = "Open \"Develop\" and press \"Start\" to start game server."
	_game_server_panel.get_start_config = func():
		var project_path = ProjectSettings.globalize_path("res://")
		return {
			"name": "game_server.start",
			"input": {
				"cwd": project_path,
				"cmd": OS.get_executable_path(),
				"args": ["--project", project_path, "--headless", "--", "--server"],
				"envs": {},
			}
		}
	_game_server_panel.get_stop_config = func():
		return {
			"name": "game_server.stop",
			"input": {}
		}
	add_control_to_bottom_panel(_game_server_panel, "Game Server")

	# Backend
	_backend_panel = preload("ui/task_panel/task_panel.tscn").instantiate()
	_backend_panel.auto_start = true
	_backend_panel.init_message = "Auto-started by Rivet plugin."
	_backend_panel.get_start_config = func():
		var project_path = ProjectSettings.globalize_path("res://")
		return {
			"name": "backend.start",
			"input": {
				"cwd": project_path,
			}
		}
	_backend_panel.get_stop_config = func():
		return {
			"name": "backend.stop",
			"input": {}
		}
	add_control_to_bottom_panel(_backend_panel, "Modules")

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
	
func _exit_tree():
	# Stop processes
	_game_server_panel.stop_task()
	_backend_panel.stop_task()

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

	# Shutdown runtime
	RivetToolchain.shutdown()

func _on_add_autoload(name: String, path: String):
	add_autoload_singleton(name, path)

func _on_focus_game_server():
	make_bottom_panel_item_visible(_game_server_panel)

func _on_focus_backend():
	make_bottom_panel_item_visible(_backend_panel)
