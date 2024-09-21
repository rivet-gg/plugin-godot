@tool extends HBoxContainer
class_name RivetBetterHSeparator

func _ready() -> void:
	%HSeparator.add_theme_constant_override("separation", int(24 * DisplayServer.screen_get_scale()))
