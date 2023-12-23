@tool extends HBoxContainer

@export var tab_container: TabContainer

var current = -1

func _ready() -> void:
	for i in get_child_count():
		var child = get_child(i)
		if child is Button:
			child.toggle_mode = true
			child.pressed.connect(_select_button.bind(i))
			if i == 0:
				child.set_pressed_no_signal(true)

func _select_button(selected: int) -> void:
	current = selected
	if tab_container:
		tab_container.set_current_tab(selected)
	for i in get_child_count():
		var child = get_child(i)
		if child is Button:
			child.set_pressed_no_signal(selected==i)


func set_current_button(button: int) -> void:
	_select_button(button)