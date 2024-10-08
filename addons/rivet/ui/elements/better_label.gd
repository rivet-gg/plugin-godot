@tool extends Label

@export var bold: bool = false

func _ready():
	if bold:
		add_theme_font_override(&"font", get_theme_font(&"bold", &"EditorFonts"))
		add_theme_font_size_override(&"bold_font_size", get_theme_font_size(&"bold_size", &"EditorFonts"))
