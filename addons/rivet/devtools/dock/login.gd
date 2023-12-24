@tool extends Control
## A button that logs the user in to the Rivet using Rivet CLI.

@onready var LogInButton: Button = %LogInButton
@onready var CloudTokenTextEdit: TextEdit = %CloudTokenTextEdit
@onready var NamespaceTokenTextEdit: TextEdit = %NamespaceTokenTextEdit
@onready var GameIdTextEdit: TextEdit = %GameIdTextEdit
@onready var ApiEndpointTextEdit: TextEdit = %ApiEndpointTextEdit

func prepare() -> void:
	var result = await RivetPluginBridge.get_plugin().cli.run_command([
		"sidekick",
		"check-login-state",
	])
	if result.exit_code == result.ExitCode.SUCCESS and "Ok" in result.output:
		owner.change_current_screen(owner.Screen.Settings)
		return

func _ready():
	LogInButton.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	%LogInButton.disabled = true
	var api_address = ApiEndpointTextEdit.text
	var result := await RivetPluginBridge.get_plugin().cli.run_command([
		"--api-endpoint",
		api_address,
		"sidekick",
		"get-link",
	])
	if result.exit_code == result.ExitCode.SUCCESS and result.output.has("Ok"):
		var data: Dictionary = result.output["Ok"]

		# Now that we have the link, open it in the user's browser
		OS.shell_open(data["device_link_url"])
		
		owner.change_current_screen(owner.Screen.Loading)

		# Long-poll the Rivet API until the user has logged in
		result = await RivetPluginBridge.get_plugin().cli.run_command([
			"--api-endpoint",
			api_address,
			"sidekick",
			"wait-for-login",
			"--device-link-token",
			data["device_link_token"],
		])

		if result.exit_code == result.ExitCode.SUCCESS:
			RivetPluginBridge.get_plugin().cloud_token = CloudTokenTextEdit.text
			RivetPluginBridge.get_plugin().namespace_token = NamespaceTokenTextEdit.text
			RivetPluginBridge.get_plugin().game_id = GameIdTextEdit.text
			RivetPluginBridge.get_plugin().api_endpoint = ApiEndpointTextEdit.text

			owner.change_current_screen(owner.Screen.Settings)

	LogInButton.disabled = false
