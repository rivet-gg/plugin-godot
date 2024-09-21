@tool extends PanelContainer
class_name TaskLogs

# See also https://github.com/godotengine/godot/blob/97b8ad1af0f2b4a216f6f1263bef4fbc69e56c7b/editor/editor_log.cpp#L465

enum LogType { STDOUT, STDERR, META }

@export var init_message: String

@onready var _log: RichTextLabel = %Log


var _color_stdout: Color
var _color_stderr: Color
var _color_meta: Color

var _strip_ansi_regex

func _ready():
	_update_theme()

	_strip_ansi_regex = RegEx.new()
	_strip_ansi_regex.compile("\\x1b\\[[0-9;]*[a-zA-Z]")

	
	if not Engine.is_editor_hint():
		if init_message != null and !init_message.is_empty():
			add_log_line(init_message, LogType.META)

func _notification(what):
	if what == NOTIFICATION_THEME_CHANGED:
		_update_theme()

func _update_theme():
	if _log == null:
		return

	var normal_font = get_theme_font("output_source", "EditorFonts")
	if normal_font:
		_log.add_theme_font_override("normal_font", normal_font)
	
	var bold_font = get_theme_font("output_source_bold", "EditorFonts")
	if bold_font:
		_log.add_theme_font_override("bold_font", bold_font)
	
	var italics_font = get_theme_font("output_source_italic", "EditorFonts")
	if italics_font:
		_log.add_theme_font_override("italics_font", italics_font)
	
	var bold_italics_font = get_theme_font("output_source_bold_italic", "EditorFonts")
	if bold_italics_font:
		_log.add_theme_font_override("bold_italics_font", bold_italics_font)
	
	var mono_font = get_theme_font("output_source_mono", "EditorFonts")
	if mono_font:
		_log.add_theme_font_override("mono_font", mono_font)
	
	# Disable padding for highlighted background/foreground
	_log.add_theme_constant_override("text_highlight_h_padding", 0)
	_log.add_theme_constant_override("text_highlight_v_padding", 0)
	
	var font_size = get_theme_font_size("output_source_size", "EditorFonts")
	_log.begin_bulk_theme_override()
	_log.add_theme_font_size_override("normal_font_size", font_size)
	_log.add_theme_font_size_override("bold_font_size", font_size)
	_log.add_theme_font_size_override("italics_font_size", font_size)
	_log.add_theme_font_size_override("mono_font_size", font_size)
	_log.end_bulk_theme_override()
	
	_color_stdout = get_theme_color("font_color", "Editor")
	_color_stderr = get_theme_color("error_color", "Editor")
	_color_meta = get_theme_color("disabled_font_color", "Editor")

func add_log_line(message: String, type: LogType):
	# Remove ANSI codes
	message = _strip_ansi_regex.sub(message, "", true)

	# Log
	if type == LogType.STDOUT:
		_log.push_color(_color_stdout)
	elif type == LogType.STDERR:
		_log.push_color(_color_stderr)
	elif type == LogType.META:
		_log.push_color(_color_meta)

	_log.add_text(message)
	_log.add_text("\n")
	
func clear_logs():
	_log.clear()
