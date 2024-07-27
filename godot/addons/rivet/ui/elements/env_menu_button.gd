@tool extends OptionButton
class_name EnvMenuButton
## A control that displays a list of environments and allows the user to select one.

enum SelectedType { LOCAL, REMOTE }

# MARK: Config
## What type of envs to show
@export var remote_only = false

# MARK: State
## Type of environment selected
var selected_type: SelectedType

## Currently selected remote env data
##
## May be null
var selected_remote_env

## Index at which the environments are inserted in the list
var _envs_idx_offset:
	get:
		if remote_only:
			return 0
		else:
			# separator + local + separator
			return 3

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

	if !remote_only:
		add_separator("Local")
		add_item("Local")

		add_separator("Remote")

	for env in environments:
		add_item("%s (%s)" % [env.display_name, env.name_id])
	add_item("+ Create Environment")

func _on_item_selected(idx: int):
	_select_menu_item(idx)

func _select_menu_item(idx: int) -> void:
	# Update selected data
	if !remote_only && (idx == 0 || idx == 1):
		# 0 = nothing selected yet, 1 = actual selection
		selected_type = SelectedType.LOCAL
		selected_remote_env = null
	elif idx >= _envs_idx_offset and idx < environments.size() + _envs_idx_offset:
		selected_type = SelectedType.REMOTE
		selected_remote_env = environments[idx - _envs_idx_offset]
	elif idx == environments.size() + _envs_idx_offset:
		_open_create_remote()
	else:
		push_error("Mismatched env menu index %s" % idx)
	
	# Update tooltip
	if selected_type == EnvMenuButton.SelectedType.LOCAL:
		tooltip_text = "Endpoint: http://localhost:6420"
	elif selected_type == EnvMenuButton.SelectedType.REMOTE:
		var endpoint = RivetPluginBridge.build_remote_env_host(selected_remote_env)
		tooltip_text = "Endpoint: %s" % endpoint

func _open_create_remote():
	# TODO: Update this to pull hub origin from bootstrap endpoint
	# Open create URL
	var plugin = RivetPluginBridge.get_plugin()
	OS.shell_open("https://hub.rivet.gg/games/%s/backend?modal=create-environment" % plugin.game_id)

	# Reset selection to local
	select(0)

func _on_plugin_bootstrapped() -> void:
	disabled = false
	selected = 0
	_update_menu_button()
	_select_menu_item(0)
