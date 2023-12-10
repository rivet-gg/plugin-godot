@tool
extends EditorPlugin

# MARK: Plugin
const AUTO_LOAD_RIVET_CLIENT = "RivetClient"
const AUTO_LOAD_RIVET_HELPER = "RivetHelper"

const RivetEditorSettings := preload("devtools/rivet_editor_settings.gd")
const RivetCLI := preload("res://addons/rivet/devtools/rivet_cli.gd")

static var cli = RivetCLI.new()

var dock: Control

func _enter_tree():
	# Add singleton
	add_autoload_singleton(AUTO_LOAD_RIVET_CLIENT, "rivet_client.gd")
	add_autoload_singleton(AUTO_LOAD_RIVET_HELPER, "rivet_helper.gd")
	
	# Add dock
	dock = preload("devtools/dock/dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)
	RivetEditorSettings.set_defaults()

func _exit_tree():
	# Remove singleton
	remove_autoload_singleton(AUTO_LOAD_RIVET_CLIENT)
	remove_autoload_singleton(AUTO_LOAD_RIVET_HELPER)
	
	# Remove dock
	remove_control_from_docks(dock)
	dock.free()

