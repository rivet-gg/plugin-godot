@tool extends Control
## Settings screens allow you to configure and deploy your game.

@onready var errorDialog: AcceptDialog = %ErrorDialog
@onready var buttons_bar: HBoxContainer = %ButtonsBar
@onready var deploy_tab = %Deploy

func _ready():
	%TabContainer.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Tree"))
	
func prepare(_args: Dictionary) -> void:
	var error = await RivetPluginBridge.instance.bootstrap()
	if error:
		errorDialog.popup_centered()
		return

func change_tab(tab: int):
	buttons_bar.set_current_button(tab)
