extends Node
class_name RivetGlobal
## Rivet [/br]
## Mainpoint of the Rivet plugin.
## It includes an easy access to APIs, helpers and tools. [/br]
## @tutorial: https://rivet.gg/learn/godot
## @experimental

enum EnvType { LOCAL, REMOTE }

# Data from the bootstrap
#
# Will be null if not bootstrapped yet
var bootstrap_data = null
var cloud_data:
	get:
		if bootstrap_data != null:
			return bootstrap_data.cloud
		else:
			return null

## If the user has the credentials required to connect to Rivet Cloud.
var is_authenticated: bool:
	get:
		return cloud_data != null

## The type of env to connect to.
var env_type = EnvType.LOCAL:
	set(value):
		env_type = value
		env_update.emit()

## ID of the selected environment.
var remote_env_id = null:
	set(value):
		remote_env_id = value
		env_update.emit()

## The full data of the env being connected to.
var remote_env = null:
	get:
		if is_authenticated && env_type == EnvType.REMOTE:
			for x in bootstrap_data.cloud.envs:
				if x.id == remote_env_id:
					return x

			# Likely has not loaded yet
			return null
		else:
			return null

# Port to run the backend on. This will be replaced on startup with a unique
# port, 6420 is a fallback.
var local_backend_port: int = 6420

var local_backend_endpoint: String:
	get:
		return "http://127.0.0.1:%s" % local_backend_port

# See local_backend_port
var local_editor_port: int = 6421

var local_editor_endpoint: String:
	get:
		return "http://127.0.0.1:%s" % local_editor_port

# Endpoint to connect to.
var backend_endpoint: String:
	get:
		if env_type == EnvType.LOCAL:
			return local_backend_endpoint
		elif env_type == EnvType.REMOTE:
			if is_authenticated:
				return cloud_data.backends[remote_env_id].endpoint
			else:
				RivetPluginBridge.warning("backeend: not authenticated")
				return ""
		else:
			RivetPluginBridge.error("backend_endpoint: unreachable")
			return ""

## If the Rivet SDK has been generated.
var backend_sdk_exists = false

## The current deployed build slug.
var current_build_slug: String:
	get:
		if env_type == EnvType.LOCAL:
			return "local"
		elif env_type == EnvType.REMOTE:
			if is_authenticated:
				var current_build = cloud_data.current_builds.get(remote_env_id)
				if current_build != null && "version" in current_build.tags:
					return current_build.tags.version
				else:
					RivetPluginBridge.log("current_build_slug: no current build or no version in build")
					return ""
			else:
				RivetPluginBridge.warning("current_build_slug: not authenticated")
				return ""
		else:
			RivetPluginBridge.error("current_build_slug: unreachable")
			return ""

# Root nodes of all the plugin UI elements
var plugin_nodes = []

## Add custom autoload via a global signal. Used for auto-generated SDK.s
signal add_autoload(name: String, path: String)

signal start_game_server()
signal stop_game_server()
signal focus_game_server()
signal game_server_state_change(running: bool)

signal start_backend()
signal stop_backend()
signal focus_backend()
signal backend_state_change(running: bool)
signal backend_config_update(event)
signal backend_sdk_update()

signal env_update()

## Helper func to spawn a task and show an alert on failure.
func run_toolchain_task(name: String, input: Variant = {}) -> Variant:
	var task = await RivetTask.with_name_input(name, input)
	add_child(task)
	task.start()
	var output = await task.task_output
	if "Ok" in output:
		return output["Ok"]
	else:
		var alert = AcceptDialog.new()
		alert.title = "Error"
		alert.dialog_text = output["Err"]
		alert.dialog_autowrap = true
		alert.close_requested.connect(func(): alert.queue_free())
		add_child(alert)
		alert.popup_centered_ratio(0.4)
		return null

## Differentiates @tool nodes from running inside of the editor vs running
## inside of the plugin UI.
func is_running_as_plugin(node: Node) -> bool:
	for plugin_node in plugin_nodes:
		if plugin_node.is_ancestor_of(node):
			return true

	return false
