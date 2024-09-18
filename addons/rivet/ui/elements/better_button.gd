@tool extends Button
class_name RivetBetterButton

@export var inspector_button: bool = false
@export var url: String

func _ready():
	self.pressed.connect(_on_pressed)
	
	if inspector_button:
		add_theme_stylebox_override("disabled", get_theme_stylebox("disabled", "InspectorActionButton"))
		add_theme_stylebox_override("hover", get_theme_stylebox("hover", "InspectorActionButton"))
		add_theme_stylebox_override("normal", get_theme_stylebox("normal", "InspectorActionButton"))
		add_theme_stylebox_override("pressed", get_theme_stylebox("pressed", "InspectorActionButton"))

func _on_pressed():
	if !url.is_empty():
		OS.shell_open(url)
