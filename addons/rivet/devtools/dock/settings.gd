@tool extends Control
## Settings screens allow you to configure and deploy your game.

@onready var errorDialog: AcceptDialog = %ErrorDialog
@onready var tabs: TabContainer = %TabContainer

@onready var deploy_tab = %Deploy
	
func prepare():
	var error = await RivetPluginBridge.instance.bootstrap()
	if error:
		errorDialog.popup_centered()
		return

func change_tab(tab: int):
	tabs.set_current_tab(tab)