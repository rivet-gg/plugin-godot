@tool extends Control

@onready var _modules_label: RichTextLabel = %ModulesLabel

func _ready() -> void:
	%ModulesContainer.add_theme_constant_override("margin_top", int(4 * DisplayServer.screen_get_scale()))
	%ModulesContainer.add_theme_constant_override("margin_bottom", int(4 * DisplayServer.screen_get_scale()))

	%AddButton.pressed.connect(_open_editor)

	if RivetPluginBridge.is_running_as_plugin(self):
		var plugin = RivetPluginBridge.get_plugin()
		plugin.backend_config_update.connect(_on_backend_config_update)

# MARK: Backend
func _on_backend_config_update(config):
	var modules_text = ""
	for module in config.modules:
		modules_text += "[b]%s[/b]\n" % module.name
		modules_text += "[[url=%s]Configure[/url]] [[url=%s]Documentation[/url]]\n" % [module.config_url, module.docs_url]
		modules_text += "\n"
	_modules_label.text = modules_text

func _on_backend_edit_config_pressed():
	var backend_json = load("res://rivet.json")
	if backend_json == null:
		var alert = AcceptDialog.new()
		alert.title = "Backend Config Does Not Exist"
		alert.dialog_text = "The rivet.json file should have been automatically created. Run 'rivet backend init' to create a new config."
		alert.dialog_autowrap = true
		alert.close_requested.connect(func(): alert.queue_free() )
		add_child(alert)
		alert.popup_centered()
		return

	EditorInterface.edit_resource(backend_json)


func _on_modules_logs_pressed():
	RivetPluginBridge.get_plugin().focus_backend.emit()

func _open_editor():
	var plugin = RivetPluginBridge.get_plugin()
	OS.shell_open(plugin.local_editor_endpoint)
