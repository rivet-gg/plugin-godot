@tool extends HBoxContainer

const _RivetLoadingButton = preload("loading_button.gd")

# Config
@export var icon: Texture2D
@export_multiline var description: String
@export var setup_text: String = "Setup"

var check_setup
var call_setup

var loading: bool:
	get: return _setup.loading
	set(value):
		_setup.loading = value

		# Fix setup button disabled state
		_update_is_setup()

# Elements
@onready var _icon: TextureRect = %Icon
@onready var _description: RichTextLabel = %Description
@onready var _setup: _RivetLoadingButton = %Setup

var _check_timer: Timer

func _ready():
	%IconContainer.add_theme_constant_override("margin_top", int(4 * DisplayServer.screen_get_scale()))

	_icon.texture = icon
	_description.text = description
	_setup.text = setup_text

	# Check status periodically in case file system changed
	_check_timer = Timer.new()
	add_child(_check_timer)
	_check_timer.timeout.connect(_update_is_setup)
	_check_timer.start(5.0)

	_update_is_setup.call_deferred()

func _update_is_setup():
	var is_setup = check_setup != null && check_setup.call()

	_setup.disabled = is_setup || loading
	_setup.text = "Complete" if is_setup else setup_text

func _on_setup_pressed():
	if call_setup != null:
		call_setup.call()
		_update_is_setup()
