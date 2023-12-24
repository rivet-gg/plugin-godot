@tool extends MarginContainer

@onready var namespace_selector: OptionButton = %DeployNamespaceSelector
@onready var manage_versions_button: Button = %ManageVersionButton
@onready var build_deploy_button: Button = %BuildDeployButton

func _ready() -> void:
    manage_versions_button.pressed.connect(_on_manage_versions_button_pressed)

func _on_manage_versions_button_pressed() -> void:
    _all_actions_set_disabled(true)
    
    var result = await RivetPluginBridge.get_plugin().cli.run_command(["sidekick", "get-version", "--namespace", namespace_selector.current_value.namespace_id])
    if result.exit_code != 0 or !("Ok" in result.output):
        print("Error: " + result.output)

    OS.shell_open(result.output["Ok"]["output"])
    _all_actions_set_disabled(false)
    
func _all_actions_set_disabled(disabled: bool) -> void:
    namespace_selector.disabled = disabled
    manage_versions_button.disabled = disabled
    build_deploy_button.disabled = disabled