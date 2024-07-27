extends Node
class_name RivetGlobal
## Rivet [/br]
## Mainpoint of the Rivet plugin.
## It includes an easy access to APIs, helpers and tools. [/br]
## @tutorial: https://rivet.gg/learn/godot
## @experimental

const _api = preload("api/rivet_api.gd")

const ApiResponse = preload("api/rivet_response.gd")
const ApiRequest = preload("api/rivet_request.gd")

const _RivetTask = preload("devtools/rivet_task.gd")

var api_endpoint: String
var backend_endpoint: String 
var game_version: String
var cloud_token: String
var game_id: String

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

## @experimental
func POST(path: String, body: Dictionary) -> _api.RivetRequest:
	return _api.POST(self, path, body)

## @experimental
func GET(path: String, body: Dictionary = {}) -> _api.RivetRequest:
	return _api.GET(self, path, body)

## @experimental
func PUT(path: String, body: Dictionary = {}) -> _api.RivetRequest:
	return _api.PUT(self, path, body)

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
