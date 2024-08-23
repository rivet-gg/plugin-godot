@tool

class_name RivetPluginBridge
## Scaffolding for the plugin to be used in the editor, this is not meant to be
## used in the game. It's a way to get the plugin instance from the engine's
## perspective.
##
## @experimental

signal bootstrapped

const _global := preload("rivet_global.gd")
const _RivetEditorSettings = preload("rivet_editor_settings.gd")

static var instance = RivetPluginBridge.new()

static func _find_plugin():
	var tree: SceneTree = Engine.get_main_loop()
	return tree.get_root().get_child(0).get_node_or_null("RivetPlugin")

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

static func log(str: String):
	if Engine.is_editor_hint():
		if _RivetEditorSettings.get_setting(_RivetEditorSettings.RIVET_DEBUG_SETTING.name):
			print("[Rivet] %s" % str)

static func warning(str: String):
	push_warning("[Rivet] %s" % str)

static func error(str: String):
	push_error("[Rivet] %s" % str)

func save_configuration():
	DirAccess.make_dir_recursive_absolute(RivetConstants.RIVET_CONFIGURATION_PATH)

	var gd_ignore_path = RivetConstants.RIVET_CONFIGURATION_PATH.path_join(".gdignore")
	if not FileAccess.file_exists(gd_ignore_path):
		var gd_ignore = FileAccess.open(gd_ignore_path, FileAccess.WRITE)
		gd_ignore.store_string("")

	var git_ignore_path = RivetConstants.RIVET_CONFIGURATION_PATH.path_join(".gitignore")
	if not FileAccess.file_exists(git_ignore_path):
		var git_ignore = FileAccess.open(git_ignore_path, FileAccess.WRITE)
		git_ignore.store_string("*")

	var plugin = get_plugin()
	var script: GDScript = GDScript.new()
	script.source_code = RivetConstants.SCRIPT_TEMPLATE.format({
		"backend_endpoint": plugin.backend_endpoint,
		"game_version": plugin.game_version,
	})
	var err: Error = ResourceSaver.save(script, RivetConstants.RIVET_CONFIGURATION_FILE_PATH)
	if err: 
		push_warning("Error saving Rivet data: %s" % err)

func bootstrap() -> Error:
	var plugin = get_plugin()
	if not plugin:
		return FAILED

	# Bootstrap
	var result = await plugin.run_toolchain_task("get_bootstrap_data")
	if result == null:
		return FAILED

	# Update config
	plugin.api_endpoint = result.api_endpoint
	plugin.cloud_token = result.token
	plugin.game_id = result.game_id
	plugin.envs = result.envs
	plugin.backends = result.backends

	save_configuration()

	emit_signal("bootstrapped")

	return OK

