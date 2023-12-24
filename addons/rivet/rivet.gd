@tool extends EditorPlugin
## Mainpoint for the Rivet editor plugin.

# MARK: Plugin
const AUTO_LOAD_RIVET_CLIENT = "RivetClient"
const AUTO_LOAD_RIVET_HELPER = "RivetHelper"
const AUTO_LOAD_RIVET_GLOBAL = "Rivet"

const _RivetEditorSettings := preload("devtools/rivet_editor_settings.gd")
const _RivetGlobal := preload("rivet_global.gd")
const _RivetCLI = preload("devtools/rivet_cli.gd")

var _dock: Control
var _export_plugin: EditorExportPlugin
var cli: _RivetCLI = _RivetCLI.new()

## The global singleton for the Rivet plugin, only available in the editor.
var global: _RivetGlobal

func _init() -> void:
	name = "RivetPlugin"

func _enter_tree():
	# Add singleton
	add_autoload_singleton(AUTO_LOAD_RIVET_CLIENT, "rivet_client.gd")
	add_autoload_singleton(AUTO_LOAD_RIVET_HELPER, "rivet_helper.gd")
	
	add_autoload_singleton(AUTO_LOAD_RIVET_GLOBAL, "rivet_global.gd")
	
	global = _RivetGlobal.new()
	global.cli = cli

	_dock = preload("devtools/dock/dock.tscn").instantiate()
	_dock.add_child(global)

	# Add export plugin
	_export_plugin = preload("devtools/rivet_export_plugin.gd").new()
	add_export_plugin(_export_plugin)

	# Add dock
	add_control_to_dock(DOCK_SLOT_LEFT_BR, _dock)
	_RivetEditorSettings.set_defaults()
	

func _exit_tree():
	# Remove singleton
	remove_autoload_singleton(AUTO_LOAD_RIVET_CLIENT)
	remove_autoload_singleton(AUTO_LOAD_RIVET_HELPER)
	remove_autoload_singleton(AUTO_LOAD_RIVET_GLOBAL)

	# Remove export plugin
	remove_export_plugin(_export_plugin)
	_export_plugin = null
	
	# Remove dock
	remove_control_from_docks(_dock)
	_dock.free()

