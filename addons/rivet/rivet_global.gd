extends Node
class_name RivetGlobal
## Rivet [/br]
## Mainpoint of the Rivet plugin.
## It includes an easy access to APIs, helpers and tools. [/br]
## @tutorial: https://rivet.gg/learn/godot
## @experimental

const _RivetTask = preload("rivet_task.gd")

# Data
var api_endpoint: String
var game_version: String
var cloud_token: String
var game_id: String
var envs
var backends

enum EnvType { LOCAL, REMOTE }

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
		if env_type == EnvType.REMOTE:
			for x in envs:
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
			return get_remote_env_endpoint(remote_env)
		else:
			push_error("backend_endpoint: unreachable")
			return ""

static func get_remote_env_endpoint(env) -> String:
	if env != null:
		# TODO: Replace with data from API endpoint
		var plugin = RivetPluginBridge.get_plugin()
		return plugin.backends[env.id].endpoint
	else:
		return "unknown"

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

signal env_update()

## Helper func to spawn a task and show an alert on failure.
func run_toolchain_task(name: String, input: Variant = {}) -> Variant:
	var output = await _RivetTask.new(name, input).task_output
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
