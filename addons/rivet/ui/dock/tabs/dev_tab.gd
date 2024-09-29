@tool extends MarginContainer

const _RivetGlobal = preload("../../../rivet_global.gd")
const _TaskPopup = preload("../../task_popup/task_popup.tscn")
const _LoadingButton = preload("../../elements/loading_button.gd")

# MARK: Environment
@onready var _warning: RichTextLabel = %WarningLabel
@onready var _env_selector = %EnvSelector

# MARK: Play
@onready var _play_type_option: OptionButton = %PlayTypeOption

@onready var _gs_start: Button = %GSStart
@onready var _gs_stop: Button = %GSStop
@onready var _gs_restart: Button = %GSRestart

# MARK: Deploy
@onready var deploy_steps_selector: OptionButton = %DeployStepsSelector
@onready var deploy_button: _LoadingButton = %DeployButton

# Will be null on Godot < 4.3
#
# We can't manually update these settings since the rest of the engine reads
# the instance count config directly from this UI
#
# See internals:
# https://github.com/godotengine/godot/blob/48403b5358c11ffff702da82c48464db8c536ee3/editor/run_instances_dialog.h
var _instances_dialog: AcceptDialog = null

func _ready() -> void:
	# Warning
	_warning.add_theme_color_override(&"default_color", get_theme_color(&"warning_color", &"Editor"))
	_warning.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	_warning.add_image(get_theme_icon("StatusWarning", "EditorIcons"))
	_warning.append_text(" Make sure you deploy the game server before testing new game logic.")	

	# General
	if RivetPluginBridge.is_running_as_plugin(self):
		RivetPluginBridge.instance.bootstrapped.connect(_on_bootstrapped)

	# Env
	%RefreshEnvButton.pressed.connect(_on_reload_env_button_pressed)
	_env_selector.item_selected.connect(func(_id): _update_selected_env())

	if RivetPluginBridge.is_running_as_plugin(self):
		RivetPluginBridge.get_plugin().env_update.connect(_update_selected_env)

	# Play
	_play_type_option.item_selected.connect(_update_play_type)

	_gs_start.pressed.connect(_on_gs_start_pressed)
	_gs_stop.pressed.connect(_on_gs_stop_pressed)
	_gs_restart.pressed.connect(_on_gs_start_pressed)

	%CustomizeInstances.pressed.connect(_on_customize_instances_pressed)
	%ServerLogs.pressed.connect(_on_gs_logs_pressed)

	if RivetPluginBridge.is_running_as_plugin(self):
		RivetPluginBridge.get_plugin().game_server_state_change.connect(_on_gs_state_change)

		_on_gs_state_change.call_deferred(false)
		_update_play_type.call_deferred(0)

	# Deploy
	deploy_button.pressed.connect(_on_deploy_button_pressed)
	%DeployServerLogsButton.pressed.connect(_open_deploy_server_logs)
	%DeployBuildListButton.pressed.connect(_open_build_list_button)
	
	# Find instances dailog
	if RivetPluginBridge.is_running_as_plugin(self):
		for child in EditorInterface.get_base_control().get_children():
			if child.is_class("RunInstancesDialog"):
				_instances_dialog = child
				break

func _on_bootstrapped() -> void:
	_update_selected_env()

# MARK: Environment
func _update_selected_env() -> void:
	var plugin = RivetPluginBridge.get_plugin()

	# HACK: Workaround dispatching bootstrap when env is null
	if plugin.env_type == _RivetGlobal.EnvType.REMOTE && plugin.remote_env == null:
		return

	var env_name
	var can_play_client
	var can_play_server
	var can_deploy
	if plugin.env_type == _RivetGlobal.EnvType.LOCAL:
		_warning.visible = false
		env_name = "Local"
		can_play_client = true
		can_play_server = true
		can_deploy = false
	elif plugin.env_type == _RivetGlobal.EnvType.REMOTE:
		env_name = plugin.remote_env.name
		if plugin.is_authenticated && plugin.remote_env_id in plugin.cloud_data.current_builds:
			_warning.visible = true
			can_play_client = true
			can_play_server = false
			can_deploy = true
		else:
			_warning.visible = false
			can_play_client = false
			can_play_server = false
			can_deploy = true
	else:
		push_error("Unknown env selector type: %s", plugin.env_type)

	# Update play type
	if can_play_server:
		_play_type_option.set_item_text(0, "Run Client & Server (%s)" % env_name)
		_play_type_option.set_item_disabled(0, false)

		_play_type_option.set_item_text(1, "Run Client Only (%s)" % env_name)
		_play_type_option.selected = 0  # This is usually the default for local dev
		_play_type_option.item_selected.emit(_play_type_option.selected)  # Emit to update UI

		_play_type_option.set_item_text(2, "Run Server (%s)" % env_name)
		_play_type_option.set_item_disabled(2, false)
	else:
		_play_type_option.set_item_text(0, "Run Client & Server (Local Environment Only)")
		_play_type_option.set_item_disabled(0, true)

		_play_type_option.set_item_text(1, "Run Client (%s)" % env_name)
		_play_type_option.selected = 1  # Force the only available option
		_play_type_option.item_selected.emit(_play_type_option.selected)  # Emit to update UI

		_play_type_option.set_item_text(2, "Run Server (Local Environment Only)")
		_play_type_option.set_item_disabled(2, true)

	# Update play button
	_gs_start.disabled = !can_play_client
	_gs_restart.disabled = !can_play_client
	if can_play_client:
		_gs_start.text = "Start"
	else:
		_gs_start.text = "Start (Server Not Deployed)"

	# Update deploy
	%DeployStepsSelector.disabled = !can_deploy
	%DeployButton.disabled = !can_deploy
	%DeployServerLogsButton.disabled = !can_deploy
	%DeployBuildListButton.disabled = !can_deploy
	if plugin.is_authenticated:
		if plugin.env_type == _RivetGlobal.EnvType.REMOTE:
			%DeployButton.text = "Deploy to " + plugin.remote_env.name
		else:
			%DeployButton.text = "Deploy (Remote Environment Only)"
	else:
		%DeployButton.text = "Deploy (Sign In Required)"

# MARK: Environments
func _on_reload_env_button_pressed():
	RivetPluginBridge.instance.bootstrap()

# MARK: Play
var _enable_play_client: bool:
	get:
		return _play_type_option.selected == 0 || _play_type_option.selected == 1

var _enable_play_server: bool:
	get:
		return _play_type_option.selected == 0 || _play_type_option.selected == 2
	
func _update_play_type(_id: int):
	%CustomizeInstances.visible = _enable_play_client && _instances_dialog != null
	%ServerLogs.visible = _enable_play_server

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

# MARK: Deploy
func _on_deploy_button_pressed() -> void:
	deploy_button.loading = true

	# Save all scenes
	EditorInterface.save_all_scenes()

	var project_path = ProjectSettings.globalize_path("res://")

	# Update selected env to remote
	var plugin = RivetPluginBridge.get_plugin()
	plugin.env_type = _RivetGlobal.EnvType.REMOTE
	plugin.env_update.emit()

	# Run deploy
	var popup = _TaskPopup.instantiate()
	popup.task_name = "deploy"
	popup.task_input = {
		"environment_id": plugin.remote_env.id,
		"cwd": project_path,
		"backend": deploy_steps_selector.selected == 0 or deploy_steps_selector.selected == 2,
		"game_server": deploy_steps_selector.selected == 0 or deploy_steps_selector.selected == 1,
	}
	add_child(popup)
	popup.popup()
	popup.task_output.connect(_on_deploy_complete)

func _on_deploy_complete(output):
	deploy_button.loading = false

	if "Ok" in output:
		# Save version
		var game_server = output["Ok"].game_server
		if game_server != null:
			var version = output["Ok"]["game_server"].version_name
			RivetPluginBridge.log("Version updated: %s" % version)
			await RivetPluginBridge.instance.bootstrap()

func _open_deploy_server_logs():
	var plugin = RivetPluginBridge.get_plugin()
	if !plugin.is_authenticated:
		RivetPluginBridge.warning("Cannot open build list if unauthenticated")
		return
	if plugin.env_type == _RivetGlobal.EnvType.REMOTE:
		OS.shell_open("https://hub.rivet.gg/games/" + plugin.cloud_data.game_id + "/environments/" + plugin.remote_env_id + "/servers")

func _open_build_list_button():
	var plugin = RivetPluginBridge.get_plugin()
	if !plugin.is_authenticated:
		RivetPluginBridge.warning("Cannot open build list if unauthenticated")
		return
	if plugin.env_type == _RivetGlobal.EnvType.REMOTE:
		OS.shell_open("https://hub.rivet.gg/games/" + plugin.cloud_data.game_id + "/environments/" + plugin.remote_env_id + "/servers/builds")
