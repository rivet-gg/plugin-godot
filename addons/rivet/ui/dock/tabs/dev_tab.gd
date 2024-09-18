@tool extends MarginContainer

const _RivetGlobal = preload("../../../rivet_global.gd")

# Environments
@onready var _warning: RichTextLabel = %WarningLabel
@onready var _env_selector = %EnvSelector

# Play
@onready var _play_type_option: OptionButton = %PlayTypeOption
# @onready var _client_count_slider: Slider = %ClientCountSlider
# @onready var _client_count_label: Label = %ClientCountLabel

@onready var _gs_start: Button = %GSStart
@onready var _gs_stop: Button = %GSStop
@onready var _gs_restart: Button = %GSRestart

# Will be null on Godot < 4.3
#
# We can't manually update these settings since the rest of the engine reads
# the instance count config directly from this UI
#
# See internals:
# https://github.com/godotengine/godot/blob/48403b5358c11ffff702da82c48464db8c536ee3/editor/run_instances_dialog.h
var _instances_dialog: AcceptDialog = null

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return # This is the scene opened in the editor!

	%ClientCountSliderContainer.add_theme_constant_override("separation", int(2 * DisplayServer.screen_get_scale()))

	# Warning
	_warning.add_theme_color_override(&"default_color", get_theme_color(&"warning_color", &"Editor"))
	_warning.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	var warning_text = _warning.text
	_warning.text = ""
	_warning.add_image(get_theme_icon("StatusWarning", "EditorIcons"))
	_warning.append_text(warning_text)	
	_warning.meta_clicked.connect(_on_deploy_button_pressed)
	
	_warning.visible = false

	# General
	RivetPluginBridge.instance.bootstrapped.connect(_on_bootstrapped)

	# Env
	RivetPluginBridge.get_plugin().env_update.connect(_update_selected_env)

	%RefreshEnvButton.pressed.connect(_on_reload_env_button_pressed)
	_env_selector.item_selected.connect(_on_env_selector_item_selected)

	# Play
	RivetPluginBridge.get_plugin().game_server_state_change.connect(_on_gs_state_change)

	_play_type_option.item_selected.connect(_update_play_type)
	# _client_count_slider.value_changed.connect(_update_client_count)

	_gs_start.pressed.connect(_on_gs_start_pressed)
	_gs_stop.pressed.connect(_on_gs_stop_pressed)
	_gs_restart.pressed.connect(_on_gs_start_pressed)

	%CustomizeInstances.pressed.connect(_on_customize_instances_pressed)
	%ServerLogs.pressed.connect(_on_gs_logs_pressed)

	# _on_client_count_change.call_deferred()
	_on_gs_state_change.call_deferred(false)
	_update_play_type.call_deferred(0)
	
	# Find instances dailog
	for child in EditorInterface.get_base_control().get_children():
		if child.is_class("RunInstancesDialog"):
			_instances_dialog = child
			break

func _on_bootstrapped() -> void:
	_update_selected_env()

func _on_env_selector_item_selected(_id: int) -> void:
	_update_selected_env()
		
func _update_selected_env() -> void:
	var plugin = RivetPluginBridge.get_plugin()
	if plugin.env_type == _RivetGlobal.EnvType.LOCAL:
		_warning.visible = false
	elif plugin.env_type == _RivetGlobal.EnvType.REMOTE:
		_warning.visible = true
	else:
		push_error("Unknown env selector type: %s", plugin.env_type)

	# Update the selected env
	RivetPluginBridge.instance.save_configuration()

func _all_actions_set_disabled(disabled: bool) -> void:
	_env_selector.disabled = disabled

func _actions_disabled_while(fn: Callable) -> void:
	_all_actions_set_disabled(true)
	await fn.call()
	_all_actions_set_disabled(false)

func _on_deploy_button_pressed() -> void:
	var plugin = RivetPluginBridge.get_plugin()
	owner.change_tab(2)
	owner.deploy_tab._env_selector.current_value = plugin.remote_env
	owner.deploy_tab._env_selector.selected = _env_selector.selected

# MARK: Environments
func _on_reload_env_button_pressed():
	RivetPluginBridge.instance.bootstrap()

# MARK: Game server
var _enable_play_client: bool:
	get:
		return _play_type_option.selected == 0 || _play_type_option.selected == 1

var _enable_play_server: bool:
	get:
		return _play_type_option.selected == 0 || _play_type_option.selected == 2
	
func _update_play_type(_id: int):
	%CustomizeInstances.visible = _enable_play_client && _instances_dialog != null
	%ServerLogs.visible = _enable_play_server
	# %ClientConfigContainer.visible = _enable_play_client

# func _update_client_count(count: float):
# 	# Convert to int
# 	count = round(count)
# 	
# 	var editor_interface = EditorInterface.get_editor_settings()
# 	if count == 1:
# 		editor_interface.set_project_metadata("debug_options", "multiple_instances_enabled", false)
# 	else:
# 		editor_interface.set_project_metadata("debug_options", "multiple_instances_enabled", true)
# 		var run_config: Array = editor_interface.get_project_metadata("debug_options", "run_instances_config")
# 		var default_entry = { "arguments": "", "features": "", "override_args": false, "override_features": false }
# 		
# 		# Add entries if needed
# 		while run_config.size() < count:
# 			run_config.append(default_entry.duplicate())
# 		
# 		# Remove entries if needed
# 		while run_config.size() > count:
# 			run_config.pop_back()
# 		
# 		editor_interface.set_project_metadata("debug_options", "run_instances_config", run_config)
# 	
# 	_on_client_count_change()
#
# func _on_client_count_change():
# 	# Read config
# 	var editor_interface = EditorInterface.get_editor_settings()
# 	var instances_enabled: bool = editor_interface.get_project_metadata("debug_options", "multiple_instances_enabled")
# 	var run_config: Array = editor_interface.get_project_metadata("debug_options", "run_instances_config")
#
# 	var count = 0
# 	if instances_enabled:
# 		count = run_config.size()
# 	else:
# 		count = 1
#
# 	_client_count_slider.value = count
# 	_client_count_label.text = "%s" % count

func _on_gs_start_pressed():
	# Start client
	if _enable_play_client:
		if EditorInterface.is_playing_scene():
			EditorInterface.stop_playing_scene()

		EditorInterface.play_main_scene()

	# Start server
	if _enable_play_server:
		RivetPluginBridge.get_plugin().start_game_server.emit()
		RivetPluginBridge.get_plugin().focus_game_server.emit()

func _on_gs_stop_pressed():
	# Stop client
	EditorInterface.stop_playing_scene()
	
	# Stop server
	RivetPluginBridge.get_plugin().stop_game_server.emit()
	RivetPluginBridge.get_plugin().focus_game_server.emit()

func _on_gs_logs_pressed():
	RivetPluginBridge.get_plugin().focus_game_server.emit()

func _on_gs_state_change(running: bool):
	_gs_start.visible = !running
	_gs_stop.visible = running
	_gs_restart.visible = running

func _on_customize_instances_pressed():
	if _instances_dialog != null:
		# Reproduce native behavior: https://github.com/godotengine/godot/blob/48403b5358c11ffff702da82c48464db8c536ee3/editor/run_instances_dialog.cpp#L158
		_instances_dialog.popup_centered(Vector2(1200, 600))
