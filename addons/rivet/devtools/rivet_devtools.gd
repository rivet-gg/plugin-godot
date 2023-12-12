@tool class_name RivetDevtools

const _global := preload("../rivet_global.gd")

## Autoload is not available for editor interfaces, we add a scoffolding to get
## the instance of the plugin from the engine's perspective
## @experimental
static func get_plugin() -> _global:
	var tree: SceneTree = Engine.get_main_loop()
	var plugin = tree.get_root().get_child(0).get_node_or_null("RivetPlugin")
	if plugin:
		return plugin.global
	push_error("Can't find Rivet Plugin")
	return null
