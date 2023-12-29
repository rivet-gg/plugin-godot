@tool extends Control
## A button that logs the user in to the Rivet using Rivet CLI.

const RivetCliOutput = preload("../rivet_cli_output.gd")

@onready var log_in_button: Button = %LogInButton
@onready var api_endpoint_line_edit: LineEdit = %ApiEndpointLineEdit
@onready var advanced_options_button: Button = %AdvancedOptionsButton
@onready var api_endpoint_field: Control = %ApiEndpointField

func prepare(_args: Dictionary) -> void:
	var result = await RivetPluginBridge.get_plugin().cli.run_and_wait([
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
	var result = await RivetPluginBridge.get_plugin().cli.run_and_wait([
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

	var link = data["device_link_url"]

	# Now that we have the link, open it in the user's browser
	OS.shell_open(link)

	var command = RivetPluginBridge.get_plugin().cli.run([
		"--api-endpoint",
		api_address,
		"sidekick",
		"wait-for-login",
		"--device-link-token",
		data["device_link_token"],
	])
	
	owner.change_current_screen(owner.Screen.LinkingPending, {
		"link": link, 
		"on_cancel": func() -> void:
			print("Killing command")
			command.kill()
	})

	command.finished.connect(
		func(result: RivetCliOutput) -> void:
		if result.exit_code != result.ExitCode.SUCCESS or !("Ok" in result.output):
			RivetPluginBridge.display_cli_error(self, result)
			log_in_button.disabled = false
			owner.change_current_screen(owner.Screen.Login)
			return
		owner.change_current_screen(owner.Screen.Settings)
	)

	command.killed.connect(
		func() -> void:
		log_in_button.disabled = false
		owner.change_current_screen(owner.Screen.Login)
	)

func _on_advanced_options_button_pressed():
	api_endpoint_field.visible = !api_endpoint_field.visible
