@tool extends Control
## Settings screens allow you to configure and deploy your game.

# TODO
const GAME_ID = "YOUR GAME ID HERE"
	
func prepare():
	var request := RivetDevtools.get_plugin().GET("/cloud/games/%s" % GAME_ID).request()
	# response.body:
	#	game.namespaces = {namespace_id, version_id, display_name}[]
	#	game.versions = {version_id, display_name}[]
	var response = await request.wait_completed()
	if response.response_code != HTTPClient.ResponseCode.RESPONSE_OK:
		push_error("Something is not right")
		return
	_populate_namespace_data(response)

func _populate_namespace_data(data: Object) -> void:
	var namespaces = data.body.game.namespaces
	
	for space in namespaces:
		var versions: Array = data.body.game.versions.filter(
			func (version): return version.version_id == space.version_id
		)
		
		if versions.is_empty():
			space["version"] = null
		else:
			space["version"] = versions[0]
	
	%AuthNamespaceSelector.namespaces = namespaces
	%DeployNamespaceSelector.namespaces = namespaces
