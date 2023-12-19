@tool extends Control
## Settings screens allow you to configure and deploy your game.

@onready var ErrorDialog: AcceptDialog = %ErrorDialog
	
func prepare():
	var error = await RivetPluginBridge.instance.bootstrap()
	if error:
		ErrorDialog.popup_centered()
		return
