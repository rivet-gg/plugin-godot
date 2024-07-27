@tool extends MarginContainer

const BACKEND_SINGLETON_NAME = "Backend"

# Environments
@onready var env_endpoint_label: RichTextLabel = %EnvEndpointLabel
@onready var env_description: RichTextLabel = %EnvironmentDescription
@onready var warning: RichTextLabel = %WarningLabel
@onready var deploy_button: Button = %DeployButton
@onready var env_selector = %AuthEnvSelector

# Backend
@onready var backend_gerate_sdk_button: Button = %BackendGenerateSdk

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return # This is the scene opened in the editor!

	env_endpoint_label.add_theme_font_override(&"mono_font", get_theme_font(&"output_source_mono", &"EditorFonts"))
	env_endpoint_label.add_theme_font_override(&"bold_font", get_theme_font(&"bold", &"EditorFonts"))
	env_endpoint_label.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	env_endpoint_label.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))

	env_description.add_theme_font_override(&"mono_font", get_theme_font(&"output_source_mono", &"EditorFonts"))
	env_description.add_theme_font_override(&"bold_font", get_theme_font(&"bold", &"EditorFonts"))
	env_description.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	env_description.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))

	warning.add_theme_color_override(&"default_color", get_theme_color(&"warning_color", &"Editor"))
	warning.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	var warning_text = warning.text
	warning.text = ""
	warning.add_image(get_theme_icon("StatusWarning", "EditorIcons"))
	warning.add_text(warning_text)	
	
	warning.visible = false
	deploy_button.visible = false

	RivetPluginBridge.instance.bootstrapped.connect(_on_bootstrapped)
	env_selector.item_selected.connect(_on_env_selector_item_selected)
	deploy_button.pressed.connect(_on_deploy_button_pressed)

func _on_bootstrapped() -> void:
	_update_selected_env()

func _on_env_selector_item_selected(_id: int) -> void:
	_update_selected_env()
		
func _update_selected_env() -> void:
	if env_selector.selected_type == EnvMenuButton.SelectedType.LOCAL:
		RivetPluginBridge.log('Selected local env')

		warning.visible = false
		deploy_button.visible = false

		_set_env_endpoint("http://localhost:6420")
	elif env_selector.selected_type == EnvMenuButton.SelectedType.REMOTE:
		RivetPluginBridge.log('Selected remote env: %s' % env_selector.selected_remote_env)

		warning.visible = true
		deploy_button.visible = true

		_set_env_endpoint(RivetPluginBridge.build_remote_env_host(env_selector.selected_remote_env))
	elif env_selector.selected_type == EnvMenuButton.SelectedType.CREATE_REMOTE:
		RivetPluginBridge.log('Selected create remote env')

		warning.visible = false
		deploy_button.visible = false
		
		# TODO: Update this to pull hub origin from bootstrap endpoint
		# Open create URL
		var plugin = RivetPluginBridge.get_plugin()
		OS.shell_open("https://hub.rivet.gg/games/%s/backend?modal=create-environment" % plugin.game_id)

		# Reset selection to local
		env_selector.select(1)
	else:
		push_error("Unknown env selector type: %s", env_selector.selected_type)

func _set_env_endpoint(endpoint: String):
	# Update UI
	env_endpoint_label.text = "[b]Endpoint:[/b] [code]%s[/code]" % endpoint
	# TODO: Write to config?


	# Update config
	RivetPluginBridge.get_plugin().backend_endpoint = endpoint
	RivetPluginBridge.instance.save_configuration()


func _all_actions_set_disabled(disabled: bool) -> void:
	env_selector.disabled = disabled

func _actions_disabled_while(fn: Callable) -> void:
	_all_actions_set_disabled(true)
	await fn.call()
	_all_actions_set_disabled(false)

func _on_deploy_button_pressed() -> void:
	owner.change_tab(1)
	owner.deploy_tab.env_selector.current_value = env_selector.selected_remote_env
	owner.deploy_tab.env_selector.selected = env_selector.selected

# MARK: Backend
func _on_backend_generate_sdk_pressed():
	# TODO: Allow configuring this
	var sdk_path = "addons/backend"
	var sdk_res_path = "res://%s" % sdk_path

	# Generate SDK
	backend_gerate_sdk_button.loading = true
	var result = await RivetPluginBridge.get_plugin().cli.run_and_wait(["sidekick", "backend-generate-sdk", "--godot", "--output-path", sdk_path])
	backend_gerate_sdk_button.loading = false
	
	# Rivet CLI error
	if result.exit_code != 0 or !("Ok" in result.output):
		RivetPluginBridge.display_cli_error(self, result)
		return

	# OpenGB error
	if result.output["Ok"].exit_code != 0:
		_full_cli_error_alert("Failed To Generate SDK", result.output["Ok"])
		return

	# Success
	var alert = AcceptDialog.new()
	alert.title = "SDK Generated Successfully"
	alert.dialog_text = "SDK generted to \"%s\".\nYou can now access the backend with the \"Backend\" singleton." % sdk_path
	alert.dialog_autowrap = true
	alert.close_requested.connect(func(): alert.queue_free() )
	add_child(alert)
	alert.popup_centered(Vector2(400, 0))

	# Nav to path
	EditorInterface.get_file_system_dock().navigate_to_path(sdk_res_path)

	# Add singleton
	RivetPluginBridge.get_plugin().add_autoload.emit(BACKEND_SINGLETON_NAME, "%s/backend.gd" % sdk_res_path)

	# TODO: Focus file system dock

func _on_backend_edit_config_pressed():
	var backend_json = load("res://backend.json")
	if backend_json == null:
		var alert = AcceptDialog.new()
		alert.title = "Backend Config Does Not Exist"
		alert.dialog_text = "The backend.json file should have been automatically created. Run 'rivet backend init' to create a new config."
		alert.dialog_autowrap = true
		alert.close_requested.connect(func(): alert.queue_free() )
		add_child(alert)
		alert.popup_centered()
		return

	EditorInterface.edit_resource(backend_json)

# TODO: Improve core error to handle this
func _full_cli_error_alert(title, cmd_result):
	# Build output details
	var dialog_text = ""
	if !cmd_result["stdout"].is_empty():
		dialog_text += cmd_result["stdout"]
	if !cmd_result["stderr"].is_empty():
		if !dialog_text.is_empty():
			dialog_text += "\n---\n"
		dialog_text += cmd_result["stderr"]
	dialog_text += "\n\nExit code: %s" % cmd_result["exit_code"]

	# Alert
	var alert = AcceptDialog.new()
	alert.title = title
	alert.dialog_text = dialog_text
	alert.dialog_autowrap = true
	alert.close_requested.connect(func(): alert.queue_free() )
	add_child(alert)
	alert.popup_centered_ratio(0.4)
	return

func _on_manage_game_server_pressed():
	# Focus the game server tab
	RivetPluginBridge.get_plugin().focus_game_server.emit()


func _on_manage_backend_pressed():
	# Focus the backend tab
	RivetPluginBridge.get_plugin().focus_backend.emit()
