@tool extends Control

func _ready():
	%LogInButton.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	%LogInButton.disabled = true
	print(Rivet.get_parent().get_children())
	var result := await Rivet.cli.link()
	
	await get_tree().create_timer(2.0).timeout
	%LogInButton.disabled = false
	if result.exit_code == result.ExitCode.SUCCESS:
		owner.change_current_screen(owner.Screen.Settings)
