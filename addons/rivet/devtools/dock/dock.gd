@tool extends Control

const Rivet := preload("../../rivet.gd")

func _ready():
	%LogInButton.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	%LogInButton.disabled = true
	var result = await Rivet.cli.link()
	print("RESULT of running `rivet --version`: ", result.formatted_output[2])
	%LogInButton.disabled = false
