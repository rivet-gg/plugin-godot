@tool extends Control
## Mainpoint of the plugin's UI

## Enum representing indexes of the children of this node
enum Screen {
	Login,
	Settings,
	Loading,
	Installer,
}

func _ready() -> void:
	change_current_screen(Screen.Installer)


func reload() -> void:
	var instance = load("res://addons/rivet/devtools/dock/dock.tscn").instantiate()
	replace_by(instance)
	instance.grab_focus()
	

func change_current_screen(scene: Screen):
	for idx in get_child_count():
		var child := get_child(idx)
		if "visible" in child:
			child.visible = idx == scene
		if idx == scene and child.has_method("prepare"):
			child.prepare()
