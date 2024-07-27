@tool extends Control

@onready var unlink_game_button: Button = %UnlinkGameButton


func _ready() -> void:
	unlink_game_button.pressed.connect(_on_unlink_game_button_pressed)


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

