@tool extends Control

@onready var InstallButton: Button = %InstallButton

func _ready() -> void:
	InstallButton.pressed.connect(_on_install_button_pressed)

func prepare() -> void:
	var plugin = RivetDevtools.get_plugin()
	if plugin and plugin.cli and plugin.cli.find_rivet():
		print(plugin.cli.find_rivet())
		owner.change_current_screen(owner.Screen.Login)
		return
	
func _on_install_button_pressed() -> void:
	InstallButton.disabled = true
	await RivetDevtools.get_plugin().cli.install()
	InstallButton.disabled = false