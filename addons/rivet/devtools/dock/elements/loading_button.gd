@tool extends Button

@export var loading: bool: set = _set_loading

var _tween: Tween

func _set_loading(value) -> void:
	loading = value
	disabled = value

	if _tween:
		_tween.kill()

	if value:
		_tween = get_tree().create_tween()

		var icons: Array[Texture2D] = [
			get_theme_icon("Progress1", "EditorIcons"),
			get_theme_icon("Progress2", "EditorIcons"),
			get_theme_icon("Progress3", "EditorIcons"),
			get_theme_icon("Progress4", "EditorIcons"),
			get_theme_icon("Progress5", "EditorIcons"),
			get_theme_icon("Progress6", "EditorIcons"),
			get_theme_icon("Progress7", "EditorIcons"),
			get_theme_icon("Progress8", "EditorIcons"),
			get_theme_icon("Progress9", "EditorIcons"),
		]
		for idx in icons.size():
			_tween.tween_property(self, "icon", icons[idx], 0 if idx == 0 else 1)
		_tween.set_loops()
	else: 
		icon = null