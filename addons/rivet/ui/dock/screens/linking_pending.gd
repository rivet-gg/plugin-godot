@tool extends VBoxContainer

@onready var link_line_edit: LineEdit = %LinkLineEdit
@onready var link_instructions: RichTextLabel = %LinkInstructions

var _on_cancel: Callable

func _ready() -> void:
	%CancelButton.pressed.connect(_on_cancel_button_pressed)

func prepare(args: Dictionary) -> void:
	if 'link' in args:
		link_line_edit.text = args['link']
		link_instructions.clear()
		link_instructions.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		link_instructions.append_spinner()
		link_instructions.append_text(" Linking game in browser...\n\n")
		link_instructions.append_text("If your browser does not open, click [url={link}]here[/url], or use link below.".format({"link": args['link']}))
		link_instructions.pop()
	if 'on_cancel' in args:
		_on_cancel = args['on_cancel']

func _on_cancel_button_pressed() -> void:
	if _on_cancel.is_valid():
		_on_cancel.call()
