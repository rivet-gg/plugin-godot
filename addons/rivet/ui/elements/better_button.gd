@tool extends Button
class_name RivetBetterButton

@export var inspector_button: bool = false
@export var url: String

func _ready():
	self.pressed.connect(_on_pressed)
	
	if inspector_button:
		var disabled = get_theme_stylebox("disabled", "InspectorActionButton")
		var hover = get_theme_stylebox("hover", "InspectorActionButton")
		var normal = get_theme_stylebox("normal", "InspectorActionButton")
		var pressed = get_theme_stylebox("pressed", "InspectorActionButton")
		
		#disabled.content_margin_right = disabled.content_margin_left
		#hover.content_margin_right = hover.content_margin_left
		#normal.content_margin_right = normal.content_margin_left
		#pressed.content_margin_right = pressed.content_margin_left
		
		add_theme_stylebox_override("disabled", disabled)
		add_theme_stylebox_override("hover", hover)
		add_theme_stylebox_override("normal", normal)
		add_theme_stylebox_override("pressed", pressed)

func _on_pressed():
	if !url.is_empty():
		OS.shell_open(url)
