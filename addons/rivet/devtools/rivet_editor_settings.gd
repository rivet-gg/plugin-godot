const RIVET_CLI_PATH_SETTING = "rivet/cli_executable_path"

## Returns the path to the Rivet CLI executable stored in the editor settings.
static func set_defaults() -> void:
	var settings := EditorInterface.get_editor_settings()
	set_default_setting_value(RIVET_CLI_PATH_SETTING, "", settings)

## Sets the path to the Rivet CLI executable in the editor settings, if it is not already set.
static func set_default_setting_value(name: String, default_value: Variant, settings: EditorSettings = EditorInterface.get_editor_settings()) -> void:
	var existing_value = settings.get_setting(name)
	settings.set_setting(name, existing_value if existing_value else default_value)

static func set_setting_value(name: String, value: Variant, settings: EditorSettings = EditorInterface.get_editor_settings()) -> void:
	settings.set_setting(name, value)

## Returns the path to the Rivet CLI executable stored in the editor settings.
static func get_setting(name: String) -> Variant:
	return EditorInterface.get_editor_settings().get_setting(name)
