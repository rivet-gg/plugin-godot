@tool class_name RivetDevtools
## Scaffolding for the plugin to be used in the editor, this is not meant to be
## used in the game. It's a way to get the plugin instance from the engine's
## perspective.
##
## @experimental

const _global := preload("../rivet_global.gd")

static func _find_plugin():
	var tree: SceneTree = Engine.get_main_loop()
	return tree.get_root().get_child(0).get_node_or_null("RivetPlugin")

## Autoload is not available for editor interfaces, we add a scoffolding to get
## the instance of the plugin from the engine's perspective
## @experimental
static func get_plugin() -> _global:
	var plugin = _find_plugin()
	if plugin:
		return plugin.global
	push_error("Can't find Rivet Plugin")
	return null


static func bootstrap() -> Error:
	var plugin = get_plugin()
	if not plugin:
		return FAILED

	var result = await get_plugin().cli.run_command([
		"sidekick",
		"get-bootstrap-data",
	])

	if result.exit_code == 0 and "Ok" in result.output:
		get_plugin().api_endpoint = result.output["Ok"].api_endpoint
		get_plugin().cloud_token = result.output["Ok"].token
		get_plugin().game_id = result.output["Ok"].game_id
		return OK
	return FAILED