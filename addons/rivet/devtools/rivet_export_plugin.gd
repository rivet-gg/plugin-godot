@tool
extends EditorExportPlugin

var has_added_file: bool = false
var _plugin_name = "RivetEditorPlugin"

func _supports_platform(platform):
	return true

func _get_name():
	return _plugin_name

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	if not FileAccess.file_exists(RivetPluginBridge.RIVET_CONFIGURATION_FILE_PATH):
		push_warning("Rivet plugin not configured. Please configure it using plugin interface.")
		return

	var configuration_file = FileAccess.open(RivetPluginBridge.RIVET_CONFIGURATION_FILE_PATH, FileAccess.READ)
	var source = configuration_file.get_as_text()
	var script = GDScript.new()
	script.source_code = source
	var error: Error = ResourceSaver.save(script, RivetPluginBridge.RIVET_DEPLOYED_CONFIGURATION_FILE_PATH)
	if not error:
		has_added_file = true


func _export_end() -> void:
	if has_added_file:
		DirAccess.remove_absolute(RivetPluginBridge.RIVET_DEPLOYED_CONFIGURATION_FILE_PATH)