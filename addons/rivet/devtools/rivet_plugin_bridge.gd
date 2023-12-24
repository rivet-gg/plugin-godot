@tool class_name RivetPluginBridge
## Scaffolding for the plugin to be used in the editor, this is not meant to be
## used in the game. It's a way to get the plugin instance from the engine's
## perspective.
##
## @experimental

signal bootstrapped

const _global := preload("../rivet_global.gd")

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

## Autoload is not available for editor interfaces, we add a scoffolding to get
## the instance of the plugin from the engine's perspective
## @experimental
static func get_plugin() -> _global:
	var plugin = _find_plugin()
	if plugin:
		return plugin.global
	push_error("Can't find Rivet Plugin")
	return null

static var game_namespaces: Array

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

	var fetch_result = await _fetch_plugin_data()
	if fetch_result == OK:
		emit_signal("bootstrapped")
	return fetch_result

func _fetch_plugin_data() -> Error:
	var request = get_plugin().GET("/cloud/games/%s" % get_plugin().game_id).request()
	var response = await request.wait_completed()
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