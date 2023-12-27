const RIVET_CLI_PATH_SETTING = {
    "name": "rivet/cli_executable_path",
    "type": TYPE_STRING,
    "hint": PROPERTY_HINT_TYPE_STRING,
}
const RIVET_DEBUG_SETTING ={
    "name": "rivet/debug",
    "type": TYPE_BOOL,
}

## Returns the path to the Rivet CLI executable stored in the editor settings.
static func set_defaults(settings: EditorSettings = EditorInterface.get_editor_settings()) -> void:
	set_default_setting_value(RIVET_CLI_PATH_SETTING["name"], "", settings)
	settings.add_property_info(RIVET_CLI_PATH_SETTING)
	set_default_setting_value(RIVET_DEBUG_SETTING["name"], false, settings)
	settings.add_property_info(RIVET_DEBUG_SETTING)

## Sets the path to the Rivet CLI executable in the editor settings, if it is not already set.
static func set_default_setting_value(name: String, default_value: Variant, settings: EditorSettings = EditorInterface.get_editor_settings()) -> void:
	var existing_value = settings.get_setting(name)
	settings.set_initial_value(name, default_value, false)
	settings.set_setting(name, existing_value if existing_value else default_value)

static func set_setting_value(name: String, value: Variant, settings: EditorSettings = EditorInterface.get_editor_settings()) -> void:
	settings.set_setting(name, value)

## Returns the path to the Rivet CLI executable stored in the editor settings.
static func get_setting(name: String, settings: EditorSettings = EditorInterface.get_editor_settings()) -> Variant:
	return settings.get_setting(name)
