@tool extends MarginContainer

@onready var namespace_selector: OptionButton = %DeployNamespaceSelector
@onready var manage_versions_button: Button = %ManageVersionButton
@onready var build_deploy_button: Button = %BuildDeployButton

func _ready() -> void:
	manage_versions_button.pressed.connect(_on_manage_versions_button_pressed)
	build_deploy_button.pressed.connect(_on_build_deploy_button_pressed)

func _on_manage_versions_button_pressed() -> void:
    _all_actions_set_disabled(true)
    
    var result = await RivetPluginBridge.get_plugin().cli.run_and_wait(["sidekick", "get-version", "--namespace", namespace_selector.current_value.namespace_id])
    if result.exit_code != 0 or !("Ok" in result.output):
        RivetPluginBridge.display_cli_error(self, result)

	OS.shell_open(result.output["Ok"]["output"])
	_all_actions_set_disabled(false)

func _on_build_deploy_button_pressed() -> void:
	# First, ask the user if they want to save their scenes
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Would you like to save before building and deploying?"
	dialog.connect("confirmed", save_before_build_and_deploy)
	dialog.get_cancel_button().pressed.connect(build_and_deploy)
	dialog.cancel_button_text = "No, just build and deploy"
	self.add_child(dialog)
	dialog.popup_centered()


func save_before_build_and_deploy() -> void:
	# Save all
	EditorInterface.save_all_scenes()
	EditorInterface.get_script_editor().save_all_scripts()

	# Now, build and deploy
	build_and_deploy()


func build_and_deploy() -> void:
	_all_actions_set_disabled(true)

	var result = await RivetPluginBridge.get_plugin().cli.run_and_wait(["sidekick", "--show-terminal", "deploy", "--namespace", namespace_selector.current_value.name_id])
	if result.exit_code != 0:
		RivetPluginBridge.display_cli_error(self, result)

	_all_actions_set_disabled(false)
	
func _all_actions_set_disabled(disabled: bool) -> void:
	namespace_selector.disabled = disabled
	manage_versions_button.disabled = disabled
	build_deploy_button.disabled = disabled
