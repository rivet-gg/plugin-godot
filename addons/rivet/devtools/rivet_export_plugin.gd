@tool
extends EditorExportPlugin

var has_added_file: bool = false
var _plugin_name = "RivetEditorPlugin"

const SCRIPT_TEMPLATE: String = """
extends RefCounted
const api_endpoint: String = \"{api_endpoint}\"
const namespace_token: String = \"{namespace_token}\"
const cloud_token: String = \"{cloud_token}\"
const game_id: String = \"{game_id}\"
"""

func _supports_platform(platform):
	return true

func _get_name():
	return _plugin_name

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	var script = GDScript.new()
	script.source_code = SCRIPT_TEMPLATE.format({
		"api_endpoint": get_plugin().api_endpoint,
		"namespace_token": get_plugin().namespace_token,
		"cloud_token": get_plugin().cloud_token,
		"game_id": get_plugin().game_id
	})
	
	var error: Error = ResourceSaver.save(script, RivetPluginBridge.RIVET_DEPLOYED_CONFIGURATION_FILE_PATH)
	if not error:
		has_added_file = true


func _export_end() -> void:
	if has_added_file:
		DirAccess.remove_absolute(RivetPluginBridge.RIVET_DEPLOYED_CONFIGURATION_FILE_PATH)