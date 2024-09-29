@tool extends HBoxContainer

const _RivetLoadingButton = preload("loading_button.gd")

signal step_complete()

# Config
@export var icon: Texture2D
@export_multiline var description: String
@export var setup_text: String = "Setup"

var check_enabled = null
var check_setup
var call_setup

var loading: bool:
	get: return _setup.loading
	set(value):
		_setup.loading = value

		# Fix setup button disabled state
		await update_state()

# Elements
@onready var _icon: TextureRect = %Icon
@onready var _description: RichTextLabel = %Description
@onready var _setup: _RivetLoadingButton = %Setup

var _check_timer: Timer

func _ready():
	%IconContainer.add_theme_constant_override("margin_top", int(8 * DisplayServer.screen_get_scale()))
	%IconContainer.add_theme_constant_override("margin_left", int(4 * DisplayServer.screen_get_scale()))

	_icon.texture = icon
	_description.text = description
	_setup.text = setup_text

	if RivetPluginBridge.is_running_as_plugin(self):
		# Check status periodically in case file system changed
		_check_timer = Timer.new()
		_check_timer.timeout.connect(update_state)
		_check_timer.wait_time = 5.0
		_check_timer.autostart = true
		add_child(_check_timer)

		update_state.call_deferred()

func update_state():
	var is_enabled = await check_enabled.call() if check_enabled != null else true
	var is_setup = check_setup != null && await check_setup.call()

	_setup.disabled = !is_enabled || is_setup || loading
	if loading:
		_setup.text = "Running"
	elif is_setup:
		_setup.text = "Complete"
	else:
		_setup.text = setup_text

func _on_setup_pressed():
	if call_setup != null:
		# Setup
		loading = true
		await call_setup.call()
		loading = false

		# Re-check state
		await update_state()

		# Notify complete
		step_complete.emit()

