@tool extends Window
class_name RivetSignIn

enum Screen {
	SignIn,
	Pending,
	Complete,
}

const _LoadingButton = preload("../elements/loading_button.gd")

var _sign_in_task = null

# MARK: Sign in
@onready var _sign_in_button: _LoadingButton = %SignInButton
@onready var _advanced_dropdown: Button = %AdvancedDropdown
@onready var _advanced_body: Node = %AdvancedBody
@onready var _api_endpoint_field: LineEdit = %ApiEndpointField

# MARK: Pending
@onready var _link_instructions: RichTextLabel = %LinkInstructions
@onready var _link_field = %LinkField

func _ready():
	var root_margin = int(8 * DisplayServer.screen_get_scale())
	%Root.add_theme_constant_override("margin_left", root_margin)
	%Root.add_theme_constant_override("margin_right", root_margin)
	%Root.add_theme_constant_override("margin_top", root_margin)
	%Root.add_theme_constant_override("margin_bottom", root_margin)
	
	var sep = int(8 * DisplayServer.screen_get_scale())
	%SignInScreen.add_theme_constant_override("separation", sep)
	%PendingScreen.add_theme_constant_override("separation", sep)
	
	_advanced_dropdown.icon = get_theme_icon("arrow", "OptionButton")
	_advanced_body.visible = false

	close_requested.connect(_on_close_requested)
	
	_sign_in_button.pressed.connect(_on_sign_in_pressed)
	_advanced_dropdown.pressed.connect(_on_advanced_pressed)

	%CancelButton.pressed.connect(_cancel_sign_in)
	
	%CompleteDismissButton.pressed.connect(_on_complete_pressed)
	
	_set_screen(Screen.SignIn)
	
	# Resize window
	var size = Vector2(
		600,
		400
	)
	min_size = size
	max_size = size

func _on_close_requested():
	_cancel_sign_in()
	hide()
	queue_free()

func _on_sign_in_pressed():
	_sign_in_button.loading = true
	var api_endpoint = _api_endpoint_field.text
	var start_result = await RivetPluginBridge.get_plugin().run_toolchain_task("auth.start_sign_in", {
		"api_endpoint": api_endpoint,
	})
	_sign_in_button.loading = false
	if start_result == null:
		return

	_start_sign_in(start_result.device_link_url)
	
	# Wait for complete
	_sign_in_task = RivetTask.with_name_input("auth.wait_for_sign_in", {
		"api_endpoint": api_endpoint,
		"device_link_token": start_result.device_link_token,
	})
	add_child(_sign_in_task)
	_sign_in_task.task_output.connect(
		func(output):
			if "Ok" in output:
				_on_sign_in_complete()
			else:
				_cancel_sign_in()
	)
	_sign_in_task.start()

func _on_advanced_pressed():
	_advanced_body.visible = !_advanced_body.visible

func _start_sign_in(link: String):
	OS.shell_open(link)

	_link_instructions.clear()
	_link_instructions.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	_link_instructions.append_spinner()
	_link_instructions.append_text(" Linking game in browser...\n\n")
	_link_instructions.append_text("If your browser does not open, click [url=%s]here[/url], or use link below." % link)
	_link_instructions.pop()
	
	_link_field.text = link
	
	_set_screen(Screen.Pending)

func _cancel_sign_in():
	if _sign_in_task != null:
		_sign_in_task.kill()
		_sign_in_task = null
	
	_set_screen(Screen.SignIn)

func _on_sign_in_complete():
	# Bootstrap new data to update UI
	RivetPluginBridge.instance.bootstrap()

	# Update screen
	_set_screen(Screen.Complete)

func _on_complete_pressed():
	hide()
	queue_free()

func _set_screen(screen: Screen):
	%SignInScreen.visible = screen == Screen.SignIn
	%PendingScreen.visible = screen == Screen.Pending
	%CompleteScreen.visible = screen == Screen.Complete
