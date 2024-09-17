@tool extends OptionButton
class_name RivetBetterOptionButton

@export var inspector_button: bool = false

func _ready():
	if inspector_button:
		add_theme_stylebox_override("disabled", get_theme_stylebox("disabled", "InspectorActionButton"))
		add_theme_stylebox_override("hover", get_theme_stylebox("hover", "InspectorActionButton"))
		add_theme_stylebox_override("normal", get_theme_stylebox("normal", "InspectorActionButton"))
		add_theme_stylebox_override("pressed", get_theme_stylebox("pressed", "InspectorActionButton"))
