@tool extends Control
## A control that displays a list of namespaces and allows the user to select one.

## Emitted when the user selects a namespace.
signal selected

@export var current_value: Dictionary
@export var namespaces: Array: set = _on_namespaces_set
@export var disabled: bool: set = _set_disabled, get = _get_disabled

@onready var menu_button: MenuButton = %MenuButton
@onready var version_label: Label = %VersionLabel

func _ready():
	_update_menu_button(namespaces)
	menu_button.selected.connect(_on_popup_id_pressed)

func _on_namespaces_set(value: Array) -> void:
	namespaces = value
	if is_inside_tree():
		_update_menu_button(value)

func _update_menu_button(value: Array) -> void:
	var popup := menu_button.get_popup()
	popup.clear()
	for item in value:
		popup.add_radio_check_item(item.display_name)

func _on_popup_id_pressed(idx: int):
	_select_menu_item(idx)

func _select_menu_item(idx: int) -> void:
	version_label.text = namespaces[idx].version.display_name if namespaces[idx].version else "unknown"
	current_value = namespaces[idx]
	selected.emit(namespaces[idx])

func _set_disabled(value: bool) -> void:
	menu_button.disabled = value

func _get_disabled() -> bool:
	return menu_button.disabled