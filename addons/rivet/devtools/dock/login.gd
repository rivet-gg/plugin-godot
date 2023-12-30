@tool extends Control
## A button that logs the user in to the Rivet using Rivet CLI.

@onready var log_in_button: Button = %LogInButton
@onready var api_endpoint_line_edit: LineEdit = %ApiEndpointLineEdit
@onready var advanced_options_button: Button = %AdvancedOptionsButton
@onready var api_endpoint_field: Control = %ApiEndpointField

func prepare() -> void:
	var result = await RivetPluginBridge.get_plugin().cli.run_command([
		"sidekick",
		"check-login-state",
	])
	if result.exit_code == result.ExitCode.SUCCESS and "Ok" in result.output:
		owner.change_current_screen(owner.Screen.Settings)
		return

func _ready():
	log_in_button.pressed.connect(_on_button_pressed)
	advanced_options_button.pressed.connect(_on_advanced_options_button_pressed)
	advanced_options_button.icon = get_theme_icon("arrow", "OptionButton")

func _on_button_pressed() -> void:
	log_in_button.disabled = true
	var api_address = api_endpoint_line_edit.text
	var result = await RivetPluginBridge.get_plugin().cli.run_command([
		"--api-endpoint",
		api_address,
		"sidekick",
		"get-link",
	])
	if result.exit_code != result.ExitCode.SUCCESS or !("Ok" in result.output):
		RivetPluginBridge.display_cli_error(self, result)
		log_in_button.disabled = false
		return
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

	if result.exit_code != result.ExitCode.SUCCESS or !("Ok" in result.output):
		RivetPluginBridge.display_cli_error(self, result)
		log_in_button.disabled = false
		return

	log_in_button.disabled = false
	owner.change_current_screen(owner.Screen.Settings)

func _on_advanced_options_button_pressed():
	api_endpoint_field.visible = !api_endpoint_field.visible
