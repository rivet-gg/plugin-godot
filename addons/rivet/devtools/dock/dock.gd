@tool extends Control

enum Screen {
	Login,
	Settings,
	Loading,
}

func _ready() -> void:
	# change_current_screen(Loading)
	# TODO: check if rivet is initialized
	# await Rivet.cli.bootstrap()
	# await get_tree().create_timer(2).timeout
	change_current_screen(Screen.Login)

func change_current_screen(scene: Screen):
	for idx in get_child_count():
		get_child(idx).visible = idx == scene
