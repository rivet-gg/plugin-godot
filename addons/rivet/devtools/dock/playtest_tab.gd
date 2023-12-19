@tool extends MarginContainer

@onready var namespace_description: RichTextLabel = %NamespaceDescription
@onready var connection_type: TabBar = %TabBar
@onready var warning: RichTextLabel = %WarningLabel
@onready var error: RichTextLabel = %ErrorLabel
@onready var namespace_selector = %AuthNamespaceSelector

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return # This is the scene opened in the editor!
	namespace_description.add_theme_font_override(&"mono_font", get_theme_font(&"output_source_mono", &"EditorFonts"))
	namespace_description.add_theme_font_override(&"bold_font", get_theme_font(&"bold", &"EditorFonts"))
	namespace_description.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))

	connection_type.add_tab(&"Local machine")
	connection_type.add_tab(&"Online server")
	connection_type.add_theme_stylebox_override(&"tab_unselected", get_theme_stylebox("normal", "Button"))
	connection_type.add_theme_stylebox_override(&"tab_hovered",	get_theme_stylebox("normal", "Button"))
	connection_type.add_theme_stylebox_override(&"tab_selected", get_theme_stylebox("normal", "Button"))

	warning.add_theme_color_override(&"default_color", get_theme_color(&"warning_color", &"Editor"))
	warning.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	var warning_text = warning.text
	warning.text = ""
	warning.add_image(get_theme_icon("StatusWarning", "EditorIcons"))
	warning.add_text(warning_text)	
	
	error.add_theme_color_override(&"default_color", get_theme_color("error_color", "Editor"))
	error.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	var error_text = error.text
	error.text = ""
	error.add_image(get_theme_icon("StatusError", "EditorIcons"))
	error.add_text(error_text)

	warning.visible = false
	error.visible = false

	connection_type.tab_selected.connect(_on_connection_type_selected)
	namespace_selector.item_selected.connect(_on_namespace_selector_item_selected)

func _on_connection_type_selected(id: int) -> void:
	_update_warnings()

func _on_namespace_selector_item_selected(id: int) -> void:
	_update_warnings()
		
func _update_warnings() -> void:
	var current_connection_type = connection_type.current_tab
	var current_namespace = namespace_selector.current_value

	# Local machine
	if current_connection_type == 0:
		warning.visible = false
		error.visible = false
		_generate_dev_auth_token(current_namespace)
		return

	# Online server
	if current_connection_type == 1:
		# It means that user hasn't deployed anything to this namespace yet
		if current_namespace.version.display_name == "0.0.1":
			warning.visible = false
			error.visible = true
		else:
			warning.visible = true
			error.visible = false
			_generate_public_auth_token(current_namespace)
		return
		
func _generate_dev_auth_token(ns) -> void:
	for i in connection_type.tab_count:
		connection_type.set_tab_disabled(i, true)
	namespace_selector.disabled = true

	var result = await RivetPluginBridge.get_plugin().cli.run_command(["sidekick", "get-namespace-dev-token", "--namespace", ns.name_id])
	if result.exit_code != 0 or !("Ok" in result.output):
		print("Error: " + result.output)
	else:
		RivetPluginBridge.get_plugin().namespace_token = result.output["Ok"]["token"]

	for i in connection_type.tab_count:
		connection_type.set_tab_disabled(i, false)
	namespace_selector.disabled = false

func _generate_public_auth_token(ns) -> void:
	pass