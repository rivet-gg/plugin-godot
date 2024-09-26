@tool extends Control

const _SignIn = preload("../../sign_in/sign_in.tscn")

@onready var _sign_in_button: Button = %SignInButton
@onready var _sign_out_button: Button = %SignOutButton

@onready var _backend_description: RichTextLabel = %BackendDescription
@onready var _backend_start: Button = %BackendStart
@onready var _backend_stop: Button = %BackendStop
@onready var _backend_restart: Button = %BackendRestart

func _ready() -> void:
	var container_margin = int(4 * DisplayServer.screen_get_scale())
	var link_separation = int(6 * DisplayServer.screen_get_scale())

	%SourceCodeMargin.add_theme_constant_override("margin_left", container_margin)
	%SourceCodeMargin.add_theme_constant_override("margin_right", container_margin)
	%SupportMargin.add_theme_constant_override("margin_left", container_margin)
	%SupportMargin.add_theme_constant_override("margin_right", container_margin)

	%GitHubLink1.add_theme_constant_override("separation", link_separation)
	%GitHubLink2.add_theme_constant_override("separation", link_separation)
	%GitHubLink3.add_theme_constant_override("separation", link_separation)

	_sign_in_button.pressed.connect(_on_sign_in_pressed)
	_sign_out_button.pressed.connect(_on_sign_out_pressed)
	
	# Wait until bootstrapped to show the appropriate button
	_sign_in_button.visible = false
	_sign_out_button.visible = false
	
	if RivetPluginBridge.is_running_as_plugin(self):
		RivetPluginBridge.instance.bootstrapped.connect(_on_plugin_bootstrapped)
		RivetPluginBridge.get_plugin().backend_state_change.connect(_on_backend_state_change)
		_on_backend_state_change.call_deferred(false)

func _on_plugin_bootstrapped():
	var plugin = RivetPluginBridge.get_plugin()
	_sign_in_button.visible = !plugin.is_authenticated
	_sign_out_button.visible = plugin.is_authenticated

# MARK: Auth
func _on_sign_in_pressed():
	var popup = _SignIn.instantiate()
	add_child(popup)
	popup.popup()

func _on_sign_out_pressed():
	# Sign out
	var result = await RivetPluginBridge.get_plugin().run_toolchain_task("auth.sign_out")

	# Update bootstrap data with signed out data. This will emit the
	# bootstrapped signal to update the UI.
	await RivetPluginBridge.instance.bootstrap()

# MARK: Plugin
func _on_edit_settings(type: String):
	# Get paths
	var paths = await RivetPluginBridge.get_plugin().run_toolchain_task("get_settings_path")

	# Decide path
	var path: String
	if type == "project":
		path = paths["project_path"]
	elif type == "user":
		path = paths["user_path"]
	else:
		push_error("_on_edit_settings: unreachable")
		return

	# Open
	await RivetPluginBridge.get_plugin().run_toolchain_task("open", { "path": path })

# MARK: Backend
func _on_backend_start_pressed():
	RivetPluginBridge.get_plugin().start_backend.emit()
	RivetPluginBridge.get_plugin().focus_backend.emit()

func _on_backend_stop_pressed():
	RivetPluginBridge.get_plugin().stop_backend.emit()
	RivetPluginBridge.get_plugin().focus_backend.emit()

func _on_backend_logs_pressed():
	RivetPluginBridge.get_plugin().focus_backend.emit()

func _on_backend_state_change(running: bool):
	_backend_start.visible = !running
	_backend_stop.visible = running
	_backend_restart.visible = running
