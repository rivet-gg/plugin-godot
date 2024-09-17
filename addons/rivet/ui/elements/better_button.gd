@tool extends Button
class_name RivetBetterButton

const STYLE_DISABLED = preload("../../theme/inspector_button/disabled.tres")
const STYLE_HOVER = preload("../../theme/inspector_button/hover.tres")
const STYLE_NORMAL = preload("../../theme/inspector_button/normal.tres")
const STYLE_PRESSED = preload("../../theme/inspector_button/pressed.tres")

@export var inspector_button: bool = false
@export var url: String

func _ready():
	self.pressed.connect(_on_pressed)
	
	if inspector_button:
		add_theme_stylebox_override("normal", STYLE_DISABLED)
		add_theme_stylebox_override("hover", STYLE_HOVER)
		add_theme_stylebox_override("normal", STYLE_NORMAL)
		add_theme_stylebox_override("pressed", STYLE_PRESSED)

func _on_pressed():
	if !url.is_empty():
		OS.shell_open(url)
