@tool extends MarginContainer

# Environments
@onready var _env_description: RichTextLabel = %EnvironmentDescription
@onready var _warning: RichTextLabel = %WarningLabel
@onready var _env_selector = %EnvSelector

# Game Server
@onready var _gs_description: RichTextLabel = %GSDescription
@onready var _gs_start: Button = %GSStart
@onready var _gs_stop: Button = %GSStop
@onready var _gs_restart: Button = %GSRestart

# Backend
@onready var _backend_sdk_gen: Button = %BackendGenerateSdk

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return # This is the scene opened in the editor!

	_warning.add_theme_color_override(&"default_color", get_theme_color(&"warning_color", &"Editor"))
	_warning.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	var warning_text = _warning.text
	_warning.text = ""
	_warning.add_image(get_theme_icon("StatusWarning", "EditorIcons"))
	_warning.append_text(warning_text)	
	_warning.meta_clicked.connect(_on_deploy_button_pressed)
	
	_warning.visible = false

	RivetPluginBridge.instance.bootstrapped.connect(_on_bootstrapped)
	RivetPluginBridge.get_plugin().game_server_state_change.connect(_on_gs_state_change)
	_env_selector.item_selected.connect(_on_env_selector_item_selected)

	_on_gs_state_change.call_deferred(false)

func _on_bootstrapped() -> void:
	_update_selected_env()

func _on_env_selector_item_selected(_id: int) -> void:
	_update_selected_env()
		
func _update_selected_env() -> void:
	if _env_selector.selected_type == EnvMenuButton.SelectedType.LOCAL:
		_warning.visible = false
		_set_env_endpoint("http://localhost:6420")
	elif _env_selector.selected_type == EnvMenuButton.SelectedType.REMOTE:
		_warning.visible = true
		_set_env_endpoint(RivetPluginBridge.build_remote_env_host(_env_selector.selected_remote_env))
	else:
		push_error("Unknown env selector type: %s", _env_selector.selected_type)

func _set_env_endpoint(endpoint: String):
	# Update config
	RivetPluginBridge.get_plugin().backend_endpoint = endpoint
	RivetPluginBridge.instance.save_configuration()

func _all_actions_set_disabled(disabled: bool) -> void:
	_env_selector.disabled = disabled

func _actions_disabled_while(fn: Callable) -> void:
	_all_actions_set_disabled(true)
	await fn.call()
	_all_actions_set_disabled(false)

func _on_deploy_button_pressed() -> void:
	owner.change_tab(2)
	owner.deploy_tab._env_selector.current_value = _env_selector.selected_remote_env
	owner.deploy_tab._env_selector.selected = _env_selector.selected

# MARK: Environments
func _on_reload_env_button_pressed():
	RivetPluginBridge.instance.bootstrap()

# MARK: Game server
func _on_gs_start_pressed():
	RivetPluginBridge.get_plugin().start_game_server.emit()
	RivetPluginBridge.get_plugin().focus_game_server.emit()

func _on_gs_stop_pressed():
	RivetPluginBridge.get_plugin().stop_game_server.emit()
	RivetPluginBridge.get_plugin().focus_game_server.emit()

func _on_gs_logs_pressed():
	RivetPluginBridge.get_plugin().focus_game_server.emit()

func _on_gs_state_change(running: bool):
	_gs_start.visible = !running
	_gs_stop.visible = running
	_gs_restart.visible = running

# MARK: Backend
func _on_backend_generate_sdk_pressed():
	_backend_sdk_gen.loading = true
	RivetUtil.generate_sdk(
		self,
		func(): _backend_sdk_gen.loading = false
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

