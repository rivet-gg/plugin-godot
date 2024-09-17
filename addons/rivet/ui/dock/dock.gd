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
