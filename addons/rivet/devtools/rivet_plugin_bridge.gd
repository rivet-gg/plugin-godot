@tool

class_name RivetPluginBridge
## Scaffolding for the plugin to be used in the editor, this is not meant to be
## used in the game. It's a way to get the plugin instance from the engine's
## perspective.
##
## @experimental

signal bootstrapped

const _global := preload("../rivet_global.gd")
const _RivetEditorSettings = preload("./rivet_editor_settings.gd")

static var game_project = null
static var game_environments: Array = []

static var instance = RivetPluginBridge.new()

static func _find_plugin():
	var tree: SceneTree = Engine.get_main_loop()
	return tree.get_root().get_child(0).get_node_or_null("RivetPlugin")

static func display_cli_error(node: Node, cli_output) -> AcceptDialog:
	var error = cli_output.output["Err"].c_unescape() if "Err" in cli_output.output else cli_output
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
	if Engine.is_editor_hint():
		if _RivetEditorSettings.get_setting(_RivetEditorSettings.RIVET_DEBUG_SETTING.name):
			print("[Rivet] ", args)

static func warning(args):
	push_warning("[Rivet] ", args)

static func error(args):
	push_error("[Rivet] ", args)

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

	var plg = get_plugin()
	var script: GDScript = GDScript.new()
	script.source_code = RivetConstants.SCRIPT_TEMPLATE.format({
		"rivet_api_endpoint": plg.api_endpoint,
		"backend_endpoint": plg.backend_endpoint,
	})
	var err: Error = ResourceSaver.save(script, RivetConstants.RIVET_CONFIGURATION_FILE_PATH)
	if err: 
		push_warning("Error saving Rivet data: %s" % err)

func bootstrap() -> Error:
	var plugin = get_plugin()
	if not plugin:
		return FAILED

	# Get bootstrap data from CLI
	var result = await get_plugin().cli.run_and_wait([
		"sidekick",
		"get-bootstrap-data",
	])
	if result.exit_code != 0 or !("Ok" in result.output):
		return FAILED
	self.log("Loaded bootstrap data: %s" % result.output["Ok"])
	
	# Update config
	get_plugin().api_endpoint = result.output["Ok"].api_endpoint
	get_plugin().cloud_token = result.output["Ok"].token
	get_plugin().game_id = result.output["Ok"].game_id

	save_configuration()

	# Fetch environments
	var fetch_result = await _fetch_envs()
	if fetch_result != OK:
		return fetch_result

	emit_signal("bootstrapped")

	return OK

## Fetch the project's environments.
func _fetch_envs() -> Error:
	var plugin = get_plugin()

	# Get project
	var proj_response = await plugin.GET("/cloud/games/%s/project" % plugin.game_id).wait_completed()
	if proj_response.response_code != HTTPClient.ResponseCode.RESPONSE_OK:
		return FAILED

	if "project" not in proj_response.body:
		RivetPluginBridge.log("TODO: Project does not exist, needs to be auto-created")
		return FAILED
	game_project = proj_response.body.project
	self.log("Loaded project: %s" % game_project)

	# Get environments
	var envs_response = await plugin.GET("/cloud/backend/projects/%s/environments" % game_project.project_id).wait_completed()
	if envs_response.response_code != HTTPClient.ResponseCode.RESPONSE_OK:
		return FAILED
	
	game_environments = envs_response.body.environments
	self.log("Loaded environments: %s" % game_environments)

	return OK

static func build_remote_env_host(env) -> String:
	# TODO: Replace with data from API endpoint
	return "https://%s--%s.backend.nathan16.gameinc.io" % [game_project.name_id, env.name_id]
