@tool extends Control

@onready var unlink_game_button: Button = %UnlinkGameButton

@onready var _backend_description: RichTextLabel = %BackendDescription
@onready var _backend_start: Button = %BackendStart
@onready var _backend_stop: Button = %BackendStop
@onready var _backend_restart: Button = %BackendRestart

func _ready() -> void:
	RivetPluginBridge.get_plugin().backend_state_change.connect(_on_backend_state_change)
	unlink_game_button.pressed.connect(_on_unlink_game_button_pressed)

	_on_backend_state_change.call_deferred(false)

# MARK: Auth
func _on_unlink_game_button_pressed() -> Error:
	unlink_game_button.disabled = true

	var result = await RivetPluginBridge.get_plugin().run_toolchain_task("unlink")
	if result == null:
		unlink_game_button.disabled = false
		return FAILED

	unlink_game_button.disabled = false
	owner.owner.reload()
	owner.owner.change_current_screen(owner.owner.Screen.Login)
	
	return OK

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
		push_error("Unreachable")
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

