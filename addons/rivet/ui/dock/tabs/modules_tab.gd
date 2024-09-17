@tool extends Control

func _ready() -> void:
	RivetPluginBridge.get_plugin().backend_state_change.connect(_on_backend_state_change)

	_on_backend_state_change.call_deferred(false)

# MARK: Backend
func _on_backend_state_change(running: bool):
	pass

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
