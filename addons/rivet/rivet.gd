@tool extends EditorPlugin
class_name RivetPlugin
## Mainpoint for the Rivet editor plugin.

# MARK: Plugin
const AUTO_LOAD_RIVET_GLOBAL = "Rivet"

const _RivetEditorSettings := preload("devtools/rivet_editor_settings.gd")
const _RivetGlobal := preload("rivet_global.gd")
const _RivetCLI = preload("devtools/rivet_cli.gd")

var _dock: Control
var _game_server_panel: Control
var _backend_panel: Control
var _export_plugin: EditorExportPlugin
var cli: _RivetCLI = _RivetCLI.new()

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
	global.cli = cli
	global.add_autoload.connect(_on_add_autoload)
	global.focus_game_server.connect(_on_focus_game_server)
	global.focus_backend.connect(_on_focus_backend)
	
	# Dock
	_dock = preload("devtools/dock/dock.tscn").instantiate()
	_dock.add_child(global)

	add_control_to_dock(DOCK_SLOT_LEFT_BR, _dock)

	# Game server
	_game_server_panel = preload("devtools/game_server/panel.tscn").instantiate()
	add_control_to_bottom_panel(_game_server_panel, "Game Server")

	# Backend
	_backend_panel = preload("devtools/backend/panel.tscn").instantiate()
	add_control_to_bottom_panel(_backend_panel, "Backend")

	# Add export plugin
	_export_plugin = preload("devtools/rivet_export_plugin.gd").new()
	add_export_plugin(_export_plugin)

	# Settings
	_RivetEditorSettings.set_defaults()
	
func _exit_tree():
	# Remove signal
	global.add_autoload.disconnect(_on_add_autoload)
	global.focus_game_server.disconnect(_on_focus_game_server)
	global.focus_backend.disconnect(_on_focus_backend)

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

func _on_add_autoload(name: String, path: String):
	add_autoload_singleton(name, path)

func _on_focus_game_server():
	make_bottom_panel_item_visible(_game_server_panel)

func _on_focus_backend():
	make_bottom_panel_item_visible(_backend_panel)
