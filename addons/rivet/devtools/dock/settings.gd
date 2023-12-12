@tool extends Control

# TODO
const GAME_ID = "92c3e1c1-6aff-427b-8914-d0e8d2b43517"

func _ready() -> void:
	self.visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	print(Rivet.get_method_list().map(func (method): return method.name))
	print(Rivet.is_inside_tree())
	var request := Rivet.GET("/cloud/games/%s" % GAME_ID).request()
	# response.body:
	#	game.namespaces = {namespace_id, version_id, display_name}[]
	#	game.versions = {version_id, display_name}[]
	var response = await request.wait_completed()
	if response.result != OK:
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
