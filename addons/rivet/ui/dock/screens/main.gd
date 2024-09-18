@tool extends Control
## Settings screens allow you to configure and deploy your game.

@onready var errorDialog: AcceptDialog = %ErrorDialog
@onready var buttons_bar: HBoxContainer = %ButtonsBar

@onready var deploy_tab = %Deploy

func _ready():
	add_theme_constant_override("separation", int(2 * DisplayServer.screen_get_scale()))

	var tab_container_margin = int(5 * DisplayServer.screen_get_scale())
	for node in [%Setup, %Develop, %Deploy, %Modules]:
		node.add_theme_constant_override("margin_left", tab_container_margin)
		node.add_theme_constant_override("margin_top", tab_container_margin)
		node.add_theme_constant_override("margin_right", tab_container_margin)
		node.add_theme_constant_override("margin_bottom", tab_container_margin)

	%TabContainer.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Tree"))
	
func prepare(_args: Dictionary) -> void:
	var error = await RivetPluginBridge.instance.bootstrap()
	if error:
		errorDialog.popup_centered()
		return

func change_tab(tab: int):
	buttons_bar.set_current_button(tab)
