class_name RivetUtil

const _task_popup = preload("ui/task_popup/task_popup.tscn")

const BACKEND_SINGLETON_NAME = "Backend"

static func generate_sdk(node: Node, complete: Callable):
	var project_path = ProjectSettings.globalize_path("res://")

	var popup = _task_popup.instantiate()
	popup.task_name = "backend_sdk_gen"
	popup.task_input = {
		"cwd": project_path,
		"fallback_sdk_path": "addons/backend",
		"target": "godot",
	}
	node.add_child(popup)
	popup.popup()

	popup.task_output.connect(
		func(output):
			complete.call()

			if "Ok" in output and output["Ok"].exit_code == 0:
				var sdk_path = output["Ok"].sdk_path
				var sdk_resource_path = "res://%s" % sdk_path

				# TODO: focus the file system dock
				# Nav to path
				EditorInterface.get_file_system_dock().navigate_to_path(sdk_resource_path)

				# Add singleton
				RivetPluginBridge.get_plugin().add_autoload.emit(BACKEND_SINGLETON_NAME, "%s/backend.gd" % sdk_resource_path)
	)

