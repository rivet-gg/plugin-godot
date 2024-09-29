@tool extends Control
## Mainpoint of the plugin's UI

const _SignIn = preload("../sign_in/sign_in.tscn")

enum Tab {
	Setup,
	Develop,
	Modules,
	Settings,
}

@onready var _tabs = {
	Tab.Setup: { button = %SetupButton, body = %Setup },
	Tab.Develop: { button = %DevelopButton, body = %Develop },
	Tab.Modules: { button = %ModulesButton, body = %Modules },
	Tab.Settings: { button = %SettingsButton, body = %Settings },
}

@onready var _sign_in_link = %SignInLink
@onready var _dashboard_link = %DashboardLink

func _ready() -> void:
	# Dock
	var dock_margin_tb = int(2 * DisplayServer.screen_get_scale())
	var dock_margin_lr = int(2 * DisplayServer.screen_get_scale())
	add_theme_constant_override("margin_left", dock_margin_lr)
	add_theme_constant_override("margin_top", dock_margin_tb)
	add_theme_constant_override("margin_right", dock_margin_lr)
	add_theme_constant_override("margin_bottom", dock_margin_tb)
	
	# Links
	_sign_in_link.visible = false
	_dashboard_link.visible = false
	
	_sign_in_link.pressed.connect(_open_sign_in)
	_dashboard_link.pressed.connect(_open_hub)

	# Logo
	var logo_margin = int(4 * DisplayServer.screen_get_scale())
	%LogoButton.add_theme_constant_override("margin_left", logo_margin)
	%LogoButton.add_theme_constant_override("margin_top", logo_margin)
	%LogoButton.add_theme_constant_override("margin_right", logo_margin)
	%LogoButton.add_theme_constant_override("margin_bottom", logo_margin)
	
	# Tabs
	%TabParent.add_theme_constant_override("separation", int(2 * DisplayServer.screen_get_scale()))

	var tab_container_margin = int(5 * DisplayServer.screen_get_scale())
	for tab in _tabs:
		_tabs[tab].button.toggle_mode = true
		_tabs[tab].button.pressed.connect(change_tab.bind(tab))
		_tabs[tab].button.add_theme_constant_override("margin_left", tab_container_margin)
		_tabs[tab].button.add_theme_constant_override("margin_top", tab_container_margin)
		_tabs[tab].button.add_theme_constant_override("margin_right", tab_container_margin)
		_tabs[tab].button.add_theme_constant_override("margin_bottom", tab_container_margin)

	%TabContainer.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Tree"))
	
	# Set default tab
	change_tab(Tab.Setup)

	if RivetPluginBridge.is_running_as_plugin(self):
		RivetPluginBridge.instance.bootstrapped.connect(_on_bootstrap)
		RivetPluginBridge.instance.bootstrap()

func _on_bootstrap():
	var plugin = RivetPluginBridge.get_plugin()
	_sign_in_link.visible = !plugin.is_authenticated
	_dashboard_link.visible = plugin.is_authenticated

func reload() -> void:
	var instance = load("res://addons/rivet/devtools/dock/dock.tscn").instantiate()
	replace_by(instance)
	instance.grab_focus()

# MARK: Links
func _open_url(url: String):
	OS.shell_open(url)
	
func _open_sign_in():
	var popup = _SignIn.instantiate()
	add_child(popup)
	popup.popup()

func _open_hub():
	var plugin = RivetPluginBridge.get_plugin()
	if plugin.is_authenticated:
		OS.shell_open("https://hub.rivet.gg/games/" + plugin.cloud_data.game_id)
	else:
		OS.shell_open("https://hub.rivet.gg")

# MARK: Tabs
func change_tab(new_tab: Tab):
	for tab in _tabs:
		var selected = tab == new_tab
		
		_tabs[tab].button.set_pressed_no_signal(selected)
		_tabs[tab].body.visible = selected
