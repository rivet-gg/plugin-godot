@tool extends OptionButton
## A control that displays a list of namespaces and allows the user to select one.

@export var current_value: Dictionary

var namespaces: Array: 
	get: return RivetPluginBridge.instance.game_namespaces

func _ready():
	if RivetPluginBridge.is_part_of_edited_scene(self):
		return
	disabled = true
	_update_menu_button(namespaces)
	item_selected.connect(_on_item_selected)
	RivetPluginBridge.instance.bootstrapped.connect(_on_plugin_bootstrapped)

func _update_menu_button(value: Array) -> void:
	clear()
	for i in value.size():
		add_item("%s (v%s)" % [namespaces[i].display_name, namespaces[i].version.display_name], i)

func _on_item_selected(idx: int):
	_select_menu_item(idx)

func _select_menu_item(idx: int) -> void:
	current_value = namespaces[idx]

func _on_plugin_bootstrapped() -> void:
	disabled = false
	_update_menu_button(namespaces)
	_select_menu_item(0)