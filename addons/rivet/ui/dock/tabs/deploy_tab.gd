@tool extends MarginContainer

const _RivetGlobal = preload("../../../rivet_global.gd")

const _task_popup = preload("../../task_popup/task_popup.tscn")
const _LoadingButton = preload("../../elements/loading_button.gd")

@onready var env_selector: OptionButton = %DeployEnvSelector
@onready var deploy_steps_selector: OptionButton = %DeployStepsSelector
@onready var deploy_button: _LoadingButton = %DeployButton

# MARK: Build & Deploy
func _on_deploy_button_pressed() -> void:
	# Save all scenes
	EditorInterface.save_all_scenes()

	# Build and deploy
	_deploy()

func _deploy():
	deploy_button.loading = true

	var project_path = ProjectSettings.globalize_path("res://")

	# Update selected env to remote
	var plugin = RivetPluginBridge.get_plugin()
	plugin.env_type = _RivetGlobal.EnvType.REMOTE
	plugin.env_update.emit()

	# Run deploy
	var popup = _task_popup.instantiate()
	popup.task_name = "deploy"
	popup.task_input = {
		"environment_id": plugin.remote_env.id,
		"cwd": project_path,
		"backend": deploy_steps_selector.selected == 0 or deploy_steps_selector.selected == 2,
		"game_server": deploy_steps_selector.selected == 0 or deploy_steps_selector.selected == 1,
	}
	add_child(popup)
	popup.popup()

	popup.task_output.connect(_on_deploy_complete)

func _on_deploy_complete(output):
	deploy_button.loading = false

	if "Ok" in output:
		# Save version
		var version = output["Ok"].version
		if !version.is_empty():
			RivetPluginBridge.get_plugin().game_version = version
			RivetPluginBridge.instance.save_configuration()

# MARK: Links
func _on_open_link(kind: String):
	var result = await RivetPluginBridge.get_plugin().run_toolchain_task("get_hub_link", {
		"kind": kind
	})
	if result == null:
		return

	OS.shell_open(result.url)

func _on_reload_env_button_pressed():
	RivetPluginBridge.instance.bootstrap()

