@tool extends MarginContainer

const ButtonsBar = preload("elements/buttons_bar.gd")

@onready var namespace_description: RichTextLabel = %NamespaceDescription
@onready var buttons_bar: ButtonsBar = %ButtonsBar
@onready var warning: RichTextLabel = %WarningLabel
@onready var error: RichTextLabel = %ErrorLabel
@onready var deploy_button: Button = %DeployButton
@onready var namespace_selector = %AuthNamespaceSelector

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return # This is the scene opened in the editor!
	namespace_description.add_theme_font_override(&"mono_font", get_theme_font(&"output_source_mono", &"EditorFonts"))
	namespace_description.add_theme_font_override(&"bold_font", get_theme_font(&"bold", &"EditorFonts"))
	namespace_description.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	namespace_description.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))

	warning.add_theme_color_override(&"default_color", get_theme_color(&"warning_color", &"Editor"))
	warning.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	var warning_text = warning.text
	warning.text = ""
	warning.add_image(get_theme_icon("StatusWarning", "EditorIcons"))
	warning.add_text(warning_text)	
	
	error.add_theme_color_override(&"default_color", get_theme_color("error_color", "Editor"))
	error.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	var error_text = error.text
	error.text = ""
	error.add_image(get_theme_icon("StatusError", "EditorIcons"))
	error.add_text(error_text)

	warning.visible = false
	error.visible = false
	deploy_button.visible = false

	RivetPluginBridge.instance.bootstrapped.connect(_on_bootstrapped)
	namespace_selector.item_selected.connect(_on_namespace_selector_item_selected)
	deploy_button.pressed.connect(_on_deploy_button_pressed)
	buttons_bar.selected.connect(_on_buttons_bar_selected)

func _on_namespace_selector_item_selected(id: int) -> void:
	_update_warnings()

func _on_buttons_bar_selected() -> void:
	_update_warnings()

func _on_bootstrapped() -> void:
	_update_warnings()
		
func _update_warnings() -> void:
	var is_local_machine = buttons_bar.current == 0
	var is_online_server = buttons_bar.current == 1
	var current_namespace = namespace_selector.current_value

	# Local machine
	if is_local_machine:
		warning.visible = false
		error.visible = false
		deploy_button.visible = false
		_generate_dev_auth_token(current_namespace)
		return

	# Online server
	if is_online_server:
		# It means that user hasn't deployed anything to this namespace yet
		if current_namespace.version.display_name == "0.0.1":
			warning.visible = false
			error.visible = true
			deploy_button.visible = true
		else:
			warning.visible = true
			error.visible = false
			deploy_button.visible = false
			_generate_public_auth_token(current_namespace)
		return

func _all_actions_set_disabled(disabled: bool) -> void:
	namespace_selector.disabled = disabled
	buttons_bar.disabled = disabled

func _generate_dev_auth_token(ns) -> void:
	_actions_disabled_while(func():
		var result = await RivetPluginBridge.get_plugin().cli.run_command(["sidekick", "get-namespace-development-token", "--namespace", ns.name_id])
		if result.exit_code != 0 or !("Ok" in result.output):
			RivetPluginBridge.display_cli_error(self, result)
			return

		RivetPluginBridge.get_plugin().namespace_token = result.output["Ok"]["token"]
		RivetPluginBridge.instance.save_configuration()
	)

func _generate_public_auth_token(ns) -> void:
	_actions_disabled_while(func():
		var result = await RivetPluginBridge.get_plugin().cli.run_command(["sidekick", "get-namespace-public-token", "--namespace", ns.name_id])
		if result.exit_code != 0 or !("Ok" in result.output):
			RivetPluginBridge.display_cli_error(self, result)
			return

		RivetPluginBridge.get_plugin().namespace_token = result.output["Ok"]["token"]
		RivetPluginBridge.instance.save_configuration()
	)

func _actions_disabled_while(fn: Callable) -> void:
	_all_actions_set_disabled(true)
	await fn.call()
	_all_actions_set_disabled(false)

func _on_deploy_button_pressed() -> void:
	owner.change_tab(1)
	owner.deploy_tab.namespace_selector.current_value = namespace_selector.current_value
	owner.deploy_tab.namespace_selector.selected = namespace_selector.selected
