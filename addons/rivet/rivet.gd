@tool extends EditorPlugin
## Mainpoint for the Rivet editor plugin.

# MARK: Plugin
const AUTO_LOAD_RIVET_CLIENT = "RivetClient"
const AUTO_LOAD_RIVET_HELPER = "RivetHelper"
const AUTO_LOAD_RIVET_GLOBAL = "Rivet"

const _RivetEditorSettings := preload("devtools/rivet_editor_settings.gd")
const _RivetGlobal := preload("res://addons/rivet/rivet_global.gd")

var _dock: Control

## The global singleton for the Rivet plugin, only available in the editor.
var global: _RivetGlobal

func _init() -> void:
	name = "RivetPlugin"

func _enter_tree():
	# Add singleton
	add_autoload_singleton(AUTO_LOAD_RIVET_CLIENT, "rivet_client.gd")
	add_autoload_singleton(AUTO_LOAD_RIVET_HELPER, "rivet_helper.gd")
	
	add_autoload_singleton(AUTO_LOAD_RIVET_GLOBAL, "rivet_global.gd")
	
	# Add dock
	_dock = preload("devtools/dock/dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, _dock)
	_RivetEditorSettings.set_defaults()
	
	global = _RivetGlobal.new()
	_dock.add_child(global)

func _exit_tree():
	# Remove singleton
	remove_autoload_singleton(AUTO_LOAD_RIVET_CLIENT)
	remove_autoload_singleton(AUTO_LOAD_RIVET_HELPER)
	remove_autoload_singleton(AUTO_LOAD_RIVET_GLOBAL)
	
	# Remove dock
	remove_control_from_docks(_dock)
	_dock.free()

