@tool extends MarginContainer

const BACKEND_SINGLETON_NAME = "Backend"

const _task_popup = preload("../task_popup/task_popup.tscn")

# Environments
@onready var env_description: RichTextLabel = %EnvironmentDescription
@onready var warning: RichTextLabel = %WarningLabel
@onready var env_selector = %EnvSelector

# Backend
@onready var backend_generate_sdk_button: Button = %BackendGenerateSdk

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return # This is the scene opened in the editor!

	env_description.add_theme_font_override(&"mono_font", get_theme_font(&"output_source_mono", &"EditorFonts"))
	env_description.add_theme_font_override(&"bold_font", get_theme_font(&"bold", &"EditorFonts"))
	env_description.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	env_description.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))

	warning.add_theme_color_override(&"default_color", get_theme_color(&"warning_color", &"Editor"))
	warning.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	var warning_text = warning.text
	warning.text = ""
	warning.add_image(get_theme_icon("StatusWarning", "EditorIcons"))
	warning.append_text(warning_text)	
	warning.meta_clicked.connect(_on_deploy_button_pressed)
	
	warning.visible = false

	RivetPluginBridge.instance.bootstrapped.connect(_on_bootstrapped)
	env_selector.item_selected.connect(_on_env_selector_item_selected)

func _on_bootstrapped() -> void:
	_update_selected_env()

func _on_env_selector_item_selected(_id: int) -> void:
	_update_selected_env()
		
func _update_selected_env() -> void:
	if env_selector.selected_type == EnvMenuButton.SelectedType.LOCAL:
		warning.visible = false
		_set_env_endpoint("http://localhost:6420")
	elif env_selector.selected_type == EnvMenuButton.SelectedType.REMOTE:
		warning.visible = true
		_set_env_endpoint(RivetPluginBridge.build_remote_env_host(env_selector.selected_remote_env))
	else:
		push_error("Unknown env selector type: %s", env_selector.selected_type)

func _set_env_endpoint(endpoint: String):
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
	backend_generate_sdk_button.loading = true

	var project_path = ProjectSettings.globalize_path("res://")
	var plugin = RivetPluginBridge.get_plugin()

	var popup = _task_popup.instantiate()
	popup.task_name = "backend_sdk_gen"
	popup.task_input = {
		"cwd": project_path,
		"fallback_sdk_path": "addons/backend",
		"target": "godot",
	}
	add_child(popup)
	popup.popup()

	popup.task_output.connect(
		func(output):
			backend_generate_sdk_button.loading = false

			if "Ok" in output and output["Ok"].exit_code == 0:
				var sdk_path = output["Ok"].sdk_path
				var sdk_resource_path = "sdk://%s" % sdk_path

				# TODO: focus the file system dock
				# Nav to path
				EditorInterface.get_file_system_dock().navigate_to_path(sdk_resource_path)

				# Add singleton
				RivetPluginBridge.get_plugin().add_autoload.emit(BACKEND_SINGLETON_NAME, "%s/backend.gd" % sdk_resource_path)
	)

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
func _full_opengb_error(title, cmd_result):
	# TODO: read stdout and stderr strings
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

func _on_reload_env_button_pressed():
	RivetPluginBridge.instance.bootstrap()
