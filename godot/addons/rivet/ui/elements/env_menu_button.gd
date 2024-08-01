@tool extends RivetBetterOptionButton
class_name EnvMenuButton
## A control that displays a list of environments and allows the user to select one.

const _RivetGlobal = preload("../../rivet_global.gd")

# MARK: Config
## What type of envs to show
@export var remote_only = false

# MARK: State
## Index at which the environments are inserted in the list
var _envs_idx_offset:
	get:
		if remote_only:
			return 0
		else:
			# separator + local + separator
			return 3

var environments: Array: 
	get:
		var plugin = RivetPluginBridge.get_plugin()
		if plugin.backend_environments != null:
			return plugin.backend_environments
		else:
			return []

func _ready():
	super()
	
	if RivetPluginBridge.is_part_of_edited_scene(self):
		return
	disabled = true
	_update_menu_button()
	item_selected.connect(_on_item_selected)

	var plugin = RivetPluginBridge.get_plugin()

	RivetPluginBridge.instance.bootstrapped.connect(_on_plugin_bootstrapped)
	plugin.env_update.connect(func():
		_update_menu_button()
	)

## Recreate environemtns and update selected index.
func _update_menu_button() -> void:
	# Insert values
	clear()

	if !remote_only:
		add_separator("Local")
		add_item("Local")

		add_separator("Remote")

	for env in environments:
		add_item("%s (%s)" % [env.display_name, env.name_id])
	add_item("+ Create Environment")

	# Update selected
	var plugin = RivetPluginBridge.get_plugin()
	if !remote_only && plugin.env_type == _RivetGlobal.EnvType.LOCAL:
		select(1)
	elif plugin.remote_env_id != null:
		if plugin.env_type == _RivetGlobal.EnvType.LOCAL:
			select(1)
		elif plugin.env_type == _RivetGlobal.EnvType.REMOTE:
			var env_idx = null
			for i in environments.size():
				if environments[i].environment_id == plugin.remote_env_id:
					env_idx = i
					break
			if env_idx != null:
				select(env_idx + _envs_idx_offset)
			else:
				push_error("_update_menu_button: unreachable on find index (%s %s)" % [plugin.remote_env_id, environments])
				return
		else:
			push_error("_update_menu_button: unreachable %s" % plugin.env_type)
			return
	else:
		# No env selected yet
		select(_envs_idx_offset)

func _on_item_selected(idx: int):
	_select_menu_item(idx)

func _select_menu_item(idx: int) -> void:
	var plugin = RivetPluginBridge.get_plugin()

	# Update selected data
	if !remote_only && (idx == 0 || idx == 1):
		# 0 = nothing selected yet, 1 = actual selection
		plugin.env_type = _RivetGlobal.EnvType.LOCAL
	elif idx >= _envs_idx_offset and idx < environments.size() + _envs_idx_offset:
		plugin.env_type = _RivetGlobal.EnvType.REMOTE
		plugin.remote_env_id = environments[idx - _envs_idx_offset].environment_id
	elif idx == environments.size() + _envs_idx_offset:
		_open_create_remote()
	else:
		push_error("Mismatched env menu index %s" % idx)
	
	# Update tooltips
	tooltip_text = "Endpoint: %s" % plugin.backend_endpoint

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
