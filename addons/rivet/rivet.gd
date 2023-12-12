@tool
extends EditorPlugin

# MARK: Plugin
const AUTO_LOAD_RIVET_CLIENT = "RivetClient"
const AUTO_LOAD_RIVET_HELPER = "RivetHelper"
const AUTO_LOAD_RIVET_GLOBAL = "Rivet"

const RivetEditorSettings := preload("devtools/rivet_editor_settings.gd")


var dock: Control

func _enter_tree():
	print("TEST")
	# Add singleton
	add_autoload_singleton(AUTO_LOAD_RIVET_CLIENT, "rivet_client.gd")
	add_autoload_singleton(AUTO_LOAD_RIVET_HELPER, "rivet_helper.gd")
	
	add_autoload_singleton(AUTO_LOAD_RIVET_GLOBAL, "rivet_global.gd")
	
	# Add dock
	dock = preload("devtools/dock/dock.tscn").instantiate()
	dock.add_child(Rivet)
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)
	RivetEditorSettings.set_defaults()
	print("THIS")

func _exit_tree():
	# Remove singleton
	remove_autoload_singleton(AUTO_LOAD_RIVET_CLIENT)
	remove_autoload_singleton(AUTO_LOAD_RIVET_HELPER)
	remove_autoload_singleton(AUTO_LOAD_RIVET_GLOBAL)
	
	# Remove dock
	remove_control_from_docks(dock)
	dock.free()

