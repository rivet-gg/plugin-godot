@tool extends HBoxContainer

@onready var logo: TextureRect = %Logo
var logo_dark = preload("../../images/icon-text-black.svg")
var logo_light = preload("../../images/icon-text-white.svg")

func _ready() -> void:
	custom_minimum_size = Vector2(
		120,
		40
		#60 * DisplayServer.screen_get_scale(),
		#20 * DisplayServer.screen_get_scale()
	)

	var is_dark = get_theme_color("font_color", "Editor").get_luminance() < 0.5
	logo.texture = logo_dark if is_dark else logo_light
