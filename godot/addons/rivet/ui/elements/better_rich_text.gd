@tool extends RichTextLabel

func _ready():
	add_theme_font_override(&"mono_font", get_theme_font(&"output_source_mono", &"EditorFonts"))
	add_theme_font_override(&"bold_font", get_theme_font(&"bold", &"EditorFonts"))
	add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
