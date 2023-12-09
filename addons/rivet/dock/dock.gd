@tool extends Control

const Rivet := preload("../rivet.gd")

func _ready():
	%LogInButton.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	Rivet.CLI.link()
