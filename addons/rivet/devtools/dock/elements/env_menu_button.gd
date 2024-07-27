@tool extends OptionButton
class_name EnvMenuButton
## A control that displays a list of environments and allows the user to select one.

enum SelectedType { LOCAL, REMOTE, CREATE_REMOTE }

## Type of environment selected
var selected_type: SelectedType

## Currently selected remote env data
##
## May be null
var selected_remote_env

## Index at which the environments are inserted in the list
const ENVIRONMENTS_IDX_OFFSET = 3 # separator + local + separator

var environments: Array: 
	get: return RivetPluginBridge.instance.game_environments

func _ready():
	if RivetPluginBridge.is_part_of_edited_scene(self):
		return
	disabled = true
	_update_menu_button()
	item_selected.connect(_on_item_selected)
	RivetPluginBridge.instance.bootstrapped.connect(_on_plugin_bootstrapped)

func _update_menu_button() -> void:
	clear()

	add_separator("Local")
	add_item("Local")

	add_separator("Remote")
	for env in environments:
		add_item("%s (%s)" % [env.display_name, env.name_id])
	add_item("+ Create Environment")

func _on_item_selected(idx: int):
	_select_menu_item(idx)

func _select_menu_item(idx: int) -> void:
	if idx == 0 or idx == 1:
		# 0 = nothing selected yet, 1 = actual selection
		selected_type = SelectedType.LOCAL
		selected_remote_env = null
	elif idx >= ENVIRONMENTS_IDX_OFFSET and idx < environments.size() + ENVIRONMENTS_IDX_OFFSET:
		selected_type = SelectedType.REMOTE
		selected_remote_env = environments[idx - ENVIRONMENTS_IDX_OFFSET]
	elif idx == environments.size() + ENVIRONMENTS_IDX_OFFSET:
		selected_type = SelectedType.CREATE_REMOTE
		selected_remote_env = null
	else:
		push_error("Mismatched env menu index %s" % idx)

func _on_plugin_bootstrapped() -> void:
	disabled = false
	selected = 0
	_update_menu_button()
	_select_menu_item(0)
