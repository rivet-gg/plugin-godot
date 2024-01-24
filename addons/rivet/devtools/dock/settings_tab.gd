@tool extends Control

@onready var unlink_game_button: Button = %UnlinkGameButton


func _ready() -> void:
	unlink_game_button.pressed.connect(_on_unlink_game_button_pressed)


func _on_unlink_game_button_pressed() -> void:
	unlink_game_button.disabled = true

	var result = await RivetPluginBridge.get_plugin().cli.run_command([
		"unlink"
	])

	if result.exit_code != result.ExitCode.SUCCESS:
		RivetPluginBridge.display_cli_error(self, result)
		unlink_game_button.disabled = false
		return

	unlink_game_button.disabled = false
	owner.owner.reload()
	owner.owner.change_current_screen(owner.owner.Screen.Login)