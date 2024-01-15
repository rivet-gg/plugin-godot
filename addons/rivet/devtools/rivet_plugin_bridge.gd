@tool class_name RivetPluginBridge
## Scaffolding for the plugin to be used in the editor, this is not meant to be
## used in the game. It's a way to get the plugin instance from the engine's
## perspective.
##
## @experimental

signal bootstrapped

const RIVET_CONFIGURATION_PATH: String = "res://.rivet"
const RIVET_CONFIGURATION_FILE_PATH: String = "res://.rivet/config.gd"
const RIVET_DEPLOYED_CONFIGURATION_FILE_PATH: String = "res://.rivet_config.gd"
const SCRIPT_TEMPLATE: String = """
extends RefCounted
const api_endpoint: String = \"{api_endpoint}\"
const namespace_token: String = \"{namespace_token}\"
const cloud_token: String = \"{cloud_token}\"
const game_id: String = \"{game_id}\"
"""
const _global := preload("../rivet_global.gd")
const _RivetEditorSettings = preload("./rivet_editor_settings.gd")

static var game_namespaces: Array

static var instance = RivetPluginBridge.new()

static func _find_plugin():
	var tree: SceneTree = Engine.get_main_loop()
	return tree.get_root().get_child(0).get_node_or_null("RivetPlugin")

static func display_cli_error(node: Node, cli_output) -> AcceptDialog:
	var error = cli_output.output["Err"].c_unescape() if "Err" in cli_output.output else "\n".join(cli_output.formatted_output)
	var alert = AcceptDialog.new()
	alert.title = "Error!"
	alert.dialog_text = error
	alert.dialog_autowrap = true
	alert.close_requested.connect(func(): alert.queue_free() )
	node.add_child(alert)
	alert.popup_centered_ratio(0.4)
	return alert

# https://github.com/godotengine/godot-proposals/issues/900#issuecomment-1812881718
static func is_part_of_edited_scene(node: Node):
	return Engine.is_editor_hint() && node.is_inside_tree() && node.get_tree().get_edited_scene_root() && (node.get_tree().get_edited_scene_root() == node || node.get_tree().get_edited_scene_root().is_ancestor_of(node))

## Autoload is not available for editor interfaces, we add a scoffolding to get
## the instance of the plugin from the engine's perspective
## @experimental
static func get_plugin() -> _global:
	var plugin = _find_plugin()
	if plugin:
		return plugin.global
	return null

static func log(args):
	if _RivetEditorSettings.get_setting(_RivetEditorSettings.RIVET_DEBUG_SETTING.name):
		print("[Rivet] ", args)

static func warning(args):
	push_warning("[Rivet] ", args)

static func error(args):
	push_error("[Rivet] ", args)

func save_configuration():
	DirAccess.make_dir_recursive_absolute(RIVET_CONFIGURATION_PATH)

	var gd_ignore_path = RIVET_CONFIGURATION_PATH.path_join(".gdignore")
	if not FileAccess.file_exists(gd_ignore_path):
		var gd_ignore = FileAccess.open(gd_ignore_path, FileAccess.WRITE)
		gd_ignore.store_string("")

	var git_ignore_path = RIVET_CONFIGURATION_PATH.path_join(".gitignore")
	if not FileAccess.file_exists(git_ignore_path):
		var git_ignore = FileAccess.open(git_ignore_path, FileAccess.WRITE)
		git_ignore.store_string("*")

	var plg = get_plugin()
	var script: GDScript = GDScript.new()
	script.source_code = SCRIPT_TEMPLATE.format({"api_endpoint": plg.api_endpoint, "namespace_token": plg.namespace_token, "cloud_token": plg.cloud_token, "game_id": plg.game_id})
	var err: Error = ResourceSaver.save(script, RIVET_CONFIGURATION_FILE_PATH)
	if err: 
		push_warning("Error saving Rivet data: %s" % err)

func bootstrap() -> Error:
	var plugin = get_plugin()
	if not plugin:
		return FAILED

	var result = await get_plugin().cli.run_command([
		"sidekick",
		"get-bootstrap-data",
	])

	if result.exit_code != 0 or !("Ok" in result.output):
		return FAILED
	
	get_plugin().api_endpoint = result.output["Ok"].api_endpoint
	get_plugin().cloud_token = result.output["Ok"].token
	get_plugin().game_id = result.output["Ok"].game_id

	save_configuration()

	var fetch_result = await _fetch_plugin_data()
	if fetch_result == OK:
		emit_signal("bootstrapped")
	return fetch_result

func _fetch_plugin_data() -> Error:
	var response = await get_plugin().GET("/cloud/games/%s" % get_plugin().game_id).wait_completed()
	# response.body:
	#	game.namespaces = {namespace_id, version_id, display_name}[]
	#	game.versions = {version_id, display_name}[]
	if response.response_code != HTTPClient.ResponseCode.RESPONSE_OK:
		return FAILED
	
	var namespaces = response.body.game.namespaces
	for space in namespaces:
		var versions: Array = response.body.game.versions.filter(
			func (version): return version.version_id == space.version_id
		)
		if versions.is_empty():
			space["version"] = null
		else:
			space["version"] = versions[0]

	game_namespaces = namespaces
	return OK
