@tool extends Control
## Mainpoint of the plugin's UI

## Enum representing indexes of the children of this node
enum Screen {
	Login,
	LinkingPending,
	Main,
}

@onready var _login: Node = %Login
@onready var _linking_pending: Node = %LinkingPending
@onready var _main: Node = %Main

func _ready() -> void:
	var dock_margin_tb = int(2 * DisplayServer.screen_get_scale())
	var dock_margin_lr = int(2 * DisplayServer.screen_get_scale())
	add_theme_constant_override("margin_left", dock_margin_lr)
	add_theme_constant_override("margin_top", dock_margin_tb)
	add_theme_constant_override("margin_right", dock_margin_lr)
	add_theme_constant_override("margin_bottom", dock_margin_tb)

	var button_margin = int(4 * DisplayServer.screen_get_scale())
	%LogoButton.add_theme_constant_override("margin_left", button_margin)
	%LogoButton.add_theme_constant_override("margin_top", button_margin)
	%LogoButton.add_theme_constant_override("margin_right", button_margin)
	%LogoButton.add_theme_constant_override("margin_bottom", button_margin)

	if RivetPluginBridge.is_running_as_plugin(self):
		change_current_screen(Screen.Login)

func reload() -> void:
	var instance = load("res://addons/rivet/devtools/dock/dock.tscn").instantiate()
	replace_by(instance)
	instance.grab_focus()
	

func change_current_screen(screen: Screen, args: Dictionary = {}):
	_login.visible = screen == Screen.Login
	_linking_pending.visible = screen == Screen.LinkingPending
	_main.visible = screen == Screen.Main

	_get_screen_node(screen).prepare(args)

func _get_screen_node(screen: Screen) -> Node:
	if screen == Screen.Login:
		return _login
	elif screen == Screen.LinkingPending:
		return _linking_pending
	elif screen == Screen.Main:
		return _main
	else:
		push_error("unknown screen")
		return null

func _open_url(url: String):
	OS.shell_open(url)

func _open_hub():
	var plugin = RivetPluginBridge.get_plugin()
	if plugin.game_id != null:
		OS.shell_open("https://hub.rivet.gg/games/" + plugin.game_id)
	else:
		OS.shell_open("https://hub.rivet.gg")
