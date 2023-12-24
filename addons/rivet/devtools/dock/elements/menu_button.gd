@tool extends MenuButton
## A menu button that emits a signal when an item is selected.

## The signal is emitted with the index of the selected item.
signal selected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_popup().id_pressed.connect(_on_popup_id_pressed)

func _on_popup_id_pressed(idx: int):
	_select_menu_item(idx)

func _select_menu_item(idx: int) -> void:
	var popup := get_popup()
	for i in range(0, popup.item_count):
		popup.set_item_checked(i, idx == i)
	text = popup.get_item_text(idx)
	selected.emit(idx)
