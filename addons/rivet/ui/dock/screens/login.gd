@tool extends Control

@onready var log_in_button: Button = %LogInButton
@onready var api_endpoint_line_edit: LineEdit = %ApiEndpointLineEdit
@onready var advanced_options_button: Button = %AdvancedOptionsButton
@onready var api_endpoint_field: Control = %ApiEndpointField

func prepare(_args: Dictionary) -> Error:
	var result = await RivetPluginBridge.get_plugin().run_toolchain_task("check_login_state")
	if result == null || !result.logged_in:
		return FAILED

	owner.change_current_screen(owner.Screen.Main)
	
	return OK

func _ready():
	log_in_button.pressed.connect(_on_button_pressed)
	advanced_options_button.pressed.connect(_on_advanced_options_button_pressed)
	advanced_options_button.icon = get_theme_icon("arrow", "OptionButton")

func _on_button_pressed() -> Error:
	log_in_button.disabled = true
	var api_endpoint = api_endpoint_line_edit.text
	var result = await RivetPluginBridge.get_plugin().run_toolchain_task("start_device_link", {
		"api_endpoint": api_endpoint,
	})
	if result == null:
		log_in_button.disabled = false
		return FAILED

	# Open link URL
	OS.shell_open(result.device_link_url)

	# Wait for complete
	var task = RivetTask.new("wait_for_login", {
		"api_endpoint": api_endpoint,
		"device_link_token": result.device_link_token,
	})
	
	owner.change_current_screen(owner.Screen.LinkingPending, {
		"link": result.device_link_url, 
		"on_cancel": func() -> void:
			print("Killing task")
			task.kill()
	})

	task.task_output.connect(
		func(result) -> void:
			if "Ok" in result:
				owner.change_current_screen(owner.Screen.Main)
			else:
				log_in_button.disabled = false
				owner.change_current_screen(owner.Screen.Login)
	)
	
	return OK

func _on_advanced_options_button_pressed():
	api_endpoint_field.visible = !api_endpoint_field.visible
