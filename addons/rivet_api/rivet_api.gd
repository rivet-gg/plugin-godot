@tool
extends EditorPlugin

# MARK: Plugin
const AUTO_LOAD_RIVET_CLIENT = "RivetClient"
const AUTO_LOAD_RIVET_HELPER = "RivetHelper"

var dock: Control

func _enter_tree():
	# Add singleton
	add_autoload_singleton(AUTO_LOAD_RIVET_CLIENT, "res://addons/rivet_api/rivet_client.gd")
	add_autoload_singleton(AUTO_LOAD_RIVET_HELPER, "res://addons/rivet_api/rivet_helper.gd")
	
	# Add dock
	dock = preload("res://addons/rivet_api/dock/dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)

func _exit_tree():
	# Remove singleton
	remove_autoload_singleton(AUTO_LOAD_RIVET_CLIENT)
	remove_autoload_singleton(AUTO_LOAD_RIVET_HELPER)
	
	# Remove dock
	remove_control_from_docks(dock)
	dock.free()

