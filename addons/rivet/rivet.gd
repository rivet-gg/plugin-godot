@tool
extends EditorPlugin

# MARK: Plugin
const AUTO_LOAD_RIVET_CLIENT = "RivetClient"
const AUTO_LOAD_RIVET_HELPER = "RivetHelper"
const AUTO_LOAD_RIVET_GLOBAL = "Rivet"

const RivetEditorSettings := preload("devtools/rivet_editor_settings.gd")
const RivetGlobal := preload("res://addons/rivet/rivet_global.gd")

var global: RivetGlobal
var dock: Control

func _init() -> void:
	name = "RivetPlugin"

func _enter_tree():
	# Add singleton
	add_autoload_singleton(AUTO_LOAD_RIVET_CLIENT, "rivet_client.gd")
	add_autoload_singleton(AUTO_LOAD_RIVET_HELPER, "rivet_helper.gd")
	
	add_autoload_singleton(AUTO_LOAD_RIVET_GLOBAL, "rivet_global.gd")
	
	# Add dock
	dock = preload("devtools/dock/dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)
	RivetEditorSettings.set_defaults()
	
	global = RivetGlobal.new()
	dock.add_child(global)

func _exit_tree():
	# Remove singleton
	remove_autoload_singleton(AUTO_LOAD_RIVET_CLIENT)
	remove_autoload_singleton(AUTO_LOAD_RIVET_HELPER)
	remove_autoload_singleton(AUTO_LOAD_RIVET_GLOBAL)
	
	# Remove dock
	remove_control_from_docks(dock)
	dock.free()

