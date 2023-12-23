@tool extends HBoxContainer

signal selected()

@export var tab_container: TabContainer

var disabled: bool = false:
	set(value):
		disabled = value
		for i in get_child_count():
			var child = get_child(i)
			if child is Button:
				child.disabled = disabled

var current = 0

func _ready() -> void:
	for i in get_child_count():
		var child = get_child(i)
		if child is Button:
			child.toggle_mode = true
			child.pressed.connect(_select_button.bind(i))
			if i == 0:
				child.set_pressed_no_signal(true)

func _select_button(curr: int) -> void:
	current = curr
	if tab_container:
		tab_container.set_current_tab(curr)
	for i in get_child_count():
		var child = get_child(i)
		if child is Button:
			child.set_pressed_no_signal(curr==i)
	selected.emit()


func set_current_button(button: int) -> void:
	_select_button(button)