@tool extends Control
## A button that logs the user in to the Rivet using Rivet CLI.


func _ready():
	%LogInButton.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	%LogInButton.disabled = true
	var result := await RivetDevtools.get_plugin().cli.link()
	%LogInButton.disabled = false
	if result.exit_code == result.ExitCode.SUCCESS:
		owner.change_current_screen(owner.Screen.Settings)
