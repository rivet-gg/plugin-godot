@tool extends Control

const Login := preload("login.tscn")
const Settings := preload("settings.tscn")
const Loading := preload("loading.tscn")
const Rivet := preload("../../rivet.gd")

var current_screen: PackedScene = null

func _ready() -> void:
	# change_current_screen(Loading)
	# TODO: check if rivet is initialized
	# await Rivet.cli.bootstrap()
	# await get_tree().create_timer(2).timeout
	change_current_screen(Login)

func change_current_screen(scene: PackedScene):
	if current_screen:
		remove_child(get_child(0))
	current_screen = scene
	var child = scene.instantiate()
	add_child(child)
	child.owner = self
