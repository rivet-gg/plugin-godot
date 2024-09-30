@tool class_name RivetPluginBridge
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

# Indicates if this script is running as part of the plugin. Helpful for @tool
# classes.
#
# https://github.com/godotengine/godot-proposals/issues/900#issuecomment-1812881718
static func is_running_as_plugin(node: Node):
	return not (Engine.is_editor_hint() && node.is_inside_tree() && node.get_tree().get_edited_scene_root() && (node.get_tree().get_edited_scene_root() == node || node.get_tree().get_edited_scene_root().is_ancestor_of(node)))

## Autoload is not available for editor interfaces, we add a scoffolding to get
## the instance of the plugin from the engine's perspective
## @experimental
static func get_plugin() -> _global:
	var plugin = _find_plugin()
	if plugin:
		return plugin.global
	RivetPluginBridge.error("Could not find plugin")
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
		"game_version": plugin.current_build_slug,
	})
	var err: Error = ResourceSaver.save(script, RivetConstants.RIVET_CONFIGURATION_FILE_PATH)
	if err: 
		push_warning("Error saving Rivet data: %s" % err)

func bootstrap() -> Error:
	# Bootstrap
	var plugin = get_plugin()
	var result = await plugin.run_toolchain_task("get_bootstrap_data")
	if result == null:
		plugin.bootstrapped = null
		bootstrapped.emit()
		return FAILED

	# Update bootstrap data
	plugin.bootstrap_data = result
	save_configuration()

	# Emit event
	bootstrapped.emit()

	return OK

func sign_in():
	var dock = _find_plugin().dock
	var api_endpoint = dock.api_endpoint
	
	var start_result = await RivetPluginBridge.get_plugin().run_toolchain_task("auth.start_sign_in", {
		"api_endpoint": api_endpoint,
	})
	if start_result == null:
		return

	OS.shell_open(start_result.device_link_url)
	
	# Wait for complete
	var wait_result = await RivetPluginBridge.get_plugin().run_toolchain_task("auth.wait_for_sign_in", {
		"api_endpoint": api_endpoint,
		"device_link_token": start_result.device_link_token,
	})
	if wait_result == null:
		return
	
	# Update bootstrap data with signed out data. This will emit the
	# bootstrapped signal to update the UI.
	await bootstrap()

func sign_out():
	# Sign out
	var result = await RivetPluginBridge.get_plugin().run_toolchain_task("auth.sign_out")

	# Update bootstrap data with signed out data. This will emit the
	# bootstrapped signal to update the UI.
	await bootstrap()
