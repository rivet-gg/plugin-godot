extends Control

signal selected

@export var namespaces: Array: set = _on_namespaces_set

@onready var menu_button: MenuButton = %MenuButton
@onready var version_label: Label = %VersionLabel

func _ready():
	_update_menu_button(namespaces)
	menu_button.get_popup().id_pressed.connect(_on_popup_id_pressed)

func _on_namespaces_set(value: Array) -> void:
	namespaces = value
	if is_inside_tree():
		_update_menu_button(value)

func _update_menu_button(value: Array) -> void:
	var popup := menu_button.get_popup()
	for item in value:
		popup.add_radio_check_item(item.display_name)

func _on_popup_id_pressed(idx: int):
	_select_menu_item(idx)

func _select_menu_item(idx: int) -> void:
	var popup := menu_button.get_popup()
	for i in range(0, popup.item_count):
		popup.set_item_checked(i, idx == i)
	menu_button.text = popup.get_item_text(idx)
	version_label.text = namespaces[idx].version.display_name if namespaces[idx].version else "unknown"
	selected.emit(namespaces[idx])
