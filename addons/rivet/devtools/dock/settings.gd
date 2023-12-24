@tool extends Control
## Settings screens allow you to configure and deploy your game.

@onready var AuthNamespaceSelector = %AuthNamespaceSelector
@onready var ConnectionMenuButton: MenuButton = %ConnectionMenuButton
@onready var DeployNamespaceSelector = %DeployNamespaceSelector
@onready var BuildDeployButton: Button = %BuildDeployButton
@onready var ManageVersionButton: Button = %ManageVersionButton

func _ready():
	ManageVersionButton.pressed.connect(_on_manage_version_button_pressed)
	DeployNamespaceSelector.selected.connect(_on_deploy_namespace_selector_selected)
	
func prepare():
	disable_all_actions(true)
	var request := RivetDevtools.get_plugin().GET("/cloud/games/%s" % RivetDevtools.get_plugin().game_id).request()
	# response.body:
	#	game.namespaces = {namespace_id, version_id, display_name}[]
	#	game.versions = {version_id, display_name}[]
	var response = await request.wait_completed()
	if response.response_code != HTTPClient.ResponseCode.RESPONSE_OK:
		push_error("Something is not right")
		return
	_populate_namespace_data(response)
	disable_all_actions(false)

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
	
	AuthNamespaceSelector.namespaces = namespaces
	DeployNamespaceSelector.namespaces = namespaces

func _on_manage_version_button_pressed() -> void:
		ManageVersionButton.disabled = true
		var result := await RivetDevtools.get_plugin().cli.run_command([
			"--api-endpoint",
			RivetDevtools.get_plugin().api_endpoint,
			"sidekick",
			"get-version",
			"--namespace",
			DeployNamespaceSelector.current_value.version_id,
		])

		if result.exit_code == result.ExitCode.SUCCESS and result.output.has("Ok"):
			var data: Dictionary = result.output["Ok"]

			OS.shell_open(data["output"])

		ManageVersionButton.disabled = false

func _on_deploy_namespace_selector_selected():
	ManageVersionButton.disabled = false
	BuildDeployButton.disabled = false

func disable_all_actions(disabled: bool) -> void:
	AuthNamespaceSelector.disabled = disabled
	ConnectionMenuButton.disabled = disabled
	DeployNamespaceSelector.disabled = disabled
	BuildDeployButton.disabled = disabled
	ManageVersionButton.disabled = disabled
