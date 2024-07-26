@tool extends MarginContainer

const ButtonsBar = preload("elements/buttons_bar.gd")

# Namespaces
@onready var namespace_description: RichTextLabel = %NamespaceDescription
@onready var buttons_bar: ButtonsBar = %ButtonsBar
@onready var warning: RichTextLabel = %WarningLabel
@onready var error: RichTextLabel = %ErrorLabel
@onready var deploy_button: Button = %DeployButton
@onready var namespace_selector = %AuthNamespaceSelector

# Game Server
var game_server_poll_timer: Timer
var game_server_pid: int = -1
@onready var game_server_start_button: Button = %GameServerStartButton
@onready var game_server_stop_button: Button = %GameServerStopButton
@onready var game_server_restart_button: Button = %GameServerRestartButton
@onready var game_server_status_label: Label = %GameServerStatusLabel
@onready var game_server_show_logs: CheckBox = %GameServerShowLogs

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return # This is the scene opened in the editor!

	namespace_description.add_theme_font_override(&"mono_font", get_theme_font(&"output_source_mono", &"EditorFonts"))
	namespace_description.add_theme_font_override(&"bold_font", get_theme_font(&"bold", &"EditorFonts"))
	namespace_description.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
	namespace_description.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))

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
	deploy_button.visible = false

	RivetPluginBridge.instance.bootstrapped.connect(_on_bootstrapped)
	namespace_selector.item_selected.connect(_on_namespace_selector_item_selected)
	deploy_button.pressed.connect(_on_deploy_button_pressed)
	buttons_bar.selected.connect(_on_buttons_bar_selected)

	game_server_poll_timer = Timer.new()
	game_server_poll_timer.wait_time = 0.5
	game_server_poll_timer.paused = true
	game_server_poll_timer.autostart = true
	game_server_poll_timer.timeout.connect(_poll_game_server_status)
	add_child(game_server_poll_timer)

	_poll_game_server_status()

func _on_namespace_selector_item_selected(id: int) -> void:
	_update_warnings()

func _on_buttons_bar_selected() -> void:
	_update_warnings()

func _on_bootstrapped() -> void:
	_update_warnings()
		
func _update_warnings() -> void:
	var is_local_machine = buttons_bar.current == 0
	var is_online_server = buttons_bar.current == 1
	var current_namespace = namespace_selector.current_value

	# Local machine
	if is_local_machine:
		warning.visible = false
		error.visible = false
		deploy_button.visible = false
		_generate_dev_auth_token(current_namespace)
		return

	# Online server
	if is_online_server:
		# It means that user hasn't deployed anything to this namespace yet
		if current_namespace.version.display_name == "0.0.1":
			warning.visible = false
			error.visible = true
			deploy_button.visible = true
		else:
			warning.visible = true
			error.visible = false
			deploy_button.visible = false
			_generate_public_auth_token(current_namespace)
		return

func _all_actions_set_disabled(disabled: bool) -> void:
	namespace_selector.disabled = disabled
	buttons_bar.disabled = disabled

func _generate_dev_auth_token(ns) -> void:
	_actions_disabled_while(func():
		if "name_id" not in ns:
			return

		var result = await RivetPluginBridge.get_plugin().cli.run_and_wait(["sidekick", "get-namespace-development-token", "--namespace", ns.name_id])
		if result.exit_code != 0 or !("Ok" in result.output):
			RivetPluginBridge.display_cli_error(self, result)
			return

		RivetPluginBridge.get_plugin().namespace_token = result.output["Ok"]["token"]
		RivetPluginBridge.instance.save_configuration()
	)

func _generate_public_auth_token(ns) -> void:
	_actions_disabled_while(func():
		if "name_id" not in ns:
			return
			
		var result = await RivetPluginBridge.get_plugin().cli.run_and_wait(["sidekick", "get-namespace-public-token", "--namespace", ns.name_id])
		if result.exit_code != 0 or !("Ok" in result.output):
			RivetPluginBridge.display_cli_error(self, result)
			return

		RivetPluginBridge.get_plugin().namespace_token = result.output["Ok"]["token"]
		RivetPluginBridge.instance.save_configuration()
	)

func _actions_disabled_while(fn: Callable) -> void:
	_all_actions_set_disabled(true)
	await fn.call()
	_all_actions_set_disabled(false)

func _on_deploy_button_pressed() -> void:
	owner.change_tab(1)
	owner.deploy_tab.namespace_selector.current_value = namespace_selector.current_value
	owner.deploy_tab.namespace_selector.selected = namespace_selector.selected


func _on_game_server_start_pressed():
	start_server()


func _on_game_server_stop_pressed():
	stop_server()

func _on_game_server_restart_pressed():
	start_server()

# MARK: Game Server
func start_server():
	if game_server_pid != -1:
		RivetPluginBridge.log("Restarting server, old pid %s" % game_server_pid)
		stop_server()

	if game_server_show_logs.button_pressed:
		# Running with logs does not have a PID we can kill
		game_server_pid = -1

		# Run via Rivet CLI to show the terminal. Get the PID from the process
		# the Rivet CLI spawned.
		var full_args = ["sidekick", "show-term", "--", OS.get_executable_path()]
		full_args.append_array(_server_run_args())
		var result = RivetPluginBridge.get_plugin().cli.run_and_wait_sync(full_args)
		if result.exit_code != 0 or !("Ok" in result.output):
			RivetPluginBridge.display_cli_error(self, result)
			return
		RivetPluginBridge.log("Started server with logs")
	else:
		# Run natively without terminal
		game_server_pid = OS.create_process(OS.get_executable_path(), _server_run_args())
		RivetPluginBridge.log("Started server without logs %s" % game_server_pid)

	_poll_game_server_status()

func stop_server():
	if game_server_pid != -1:
		RivetPluginBridge.log("Stopped serer %s" % game_server_pid)
		OS.kill(game_server_pid)
		game_server_pid = -1
		_poll_game_server_status()
	else:
		RivetPluginBridge.log("Server not running")

func _server_run_args() -> PackedStringArray:
	var project_path = ProjectSettings.globalize_path("res://")
	return ["--path", project_path, "--headless", "--", "--server"]

## Checks if the server process is still running.
func _poll_game_server_status():
	# Check if server still running
	if game_server_pid != -1 and !OS.is_process_running(game_server_pid):
		RivetPluginBridge.log("Server process exited %s" % game_server_pid)
		game_server_pid = -1
	
	# Update stop button
	if game_server_pid != -1:
		game_server_poll_timer.paused = false
		game_server_status_label.text = "Game server running (pid %s)" % game_server_pid
		game_server_start_button.visible = false
		game_server_stop_button.visible = true
		game_server_restart_button.visible = true
		game_server_status_label.visible = true
		game_server_show_logs.visible = false
	else:
		game_server_poll_timer.paused = true
		game_server_start_button.visible = true
		game_server_stop_button.visible = false
		game_server_restart_button.visible = false
		game_server_status_label.visible = false
		game_server_show_logs.visible = true
