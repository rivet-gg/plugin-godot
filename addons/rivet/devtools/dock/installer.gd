@tool extends Control

@onready var InstallButton: Button = %InstallButton
@onready var InstallDialog: AcceptDialog = %InstallDialog
@onready var InstallLabel: RichTextLabel = %InstallLabel

func prepare() -> void:
	InstallLabel.add_theme_font_override(&"mono_font", get_theme_font(&"output_source_mono", &"EditorFonts"))
	InstallLabel.add_theme_font_override(&"bold_font", get_theme_font(&"bold", &"EditorFonts"))
	InstallLabel.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))

	InstallLabel.text = InstallLabel.text.replace(&"%%version%%", RivetDevtools.get_plugin().cli.REQUIRED_RIVET_CLI_VERSION).replace(&"%%bin_dir%%", RivetDevtools.get_plugin().cli.get_bin_dir())
	InstallButton.disabled = true
	var error = await RivetDevtools.get_plugin().cli.check_existence()
	if error:
		InstallButton.disabled = false
		return
	owner.change_current_screen(owner.Screen.Login)

func _ready() -> void:
	InstallButton.pressed.connect(_on_install_button_pressed)

func _on_install_button_pressed() -> void:	
	InstallButton.disabled = true
	var result = await RivetDevtools.get_plugin().cli.install()
	if "Ok" in result.output:
		InstallDialog.title = &"Success!"
		InstallDialog.dialog_text = &"Rivet installed successfully!\nInstalled Rivet %s in %s" % [result.output["Ok"]["version"], RivetDevtools.get_plugin().cli.get_bin_dir()]
		InstallDialog.popup_centered()
		owner.change_current_screen(owner.Screen.Login)
		return
	InstallDialog.title = &"Error!"
	InstallDialog.dialog_text = &"Rivet installation failed! Please try again.\n\n%s" % result.output
	InstallDialog.popup_centered()
	InstallButton.disabled = false