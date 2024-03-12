@tool extends RichTextLabel

var _spinner_tween: Tween

func _ready():
    add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
    add_theme_font_override(&"mono_font", get_theme_font(&"output_source_mono", &"EditorFonts"))
    add_theme_font_override(&"bold_font", get_theme_font(&"bold", &"EditorFonts"))
	
    meta_clicked.connect(func(meta): OS.shell_open(str(meta)))

func _exit_tree() -> void:
    if _spinner_tween:
        _spinner_tween.kill()

func append_spinner():
    if _spinner_tween:
        _spinner_tween.kill()
    add_image(get_theme_icon(&"Progress1", &"EditorIcons"), 0, 0, Color(1, 1, 1, 1), 5, Rect2(0,0,0,0), "loading")
    _spinner_tween = get_tree().create_tween()
    _spinner_tween.tween_method(_on_spinner_tween_method, 1, 8, 1).set_delay(0.1)
    _spinner_tween.set_loops()

func _on_spinner_tween_method(frame: int):
    update_image("loading", ImageUpdateMask.UPDATE_TEXTURE, get_theme_icon("Progress" + str(frame), "EditorIcons"))