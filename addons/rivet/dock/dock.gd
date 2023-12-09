@tool extends Control

const CLI := preload("../scripts/rivet_cli.gd")

func _ready():
	%LogInButton.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	CLI.link()
