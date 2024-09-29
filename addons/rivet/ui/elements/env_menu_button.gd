@tool extends RivetBetterOptionButton
class_name EnvMenuButton
## A control that displays a list of environments and allows the user to select one.

const _RivetGlobal = preload("../../rivet_global.gd")
const _SignIn = preload("../sign_in/sign_in.tscn")

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
		if plugin.is_authenticated && plugin.cloud_data.envs != null:
			return plugin.cloud_data.envs
		else:
			return []

func _ready():
	super()
	
	disabled = true
	item_selected.connect(_on_item_selected)

	if RivetPluginBridge.is_running_as_plugin(self):
		_update_menu_button()

		var plugin = RivetPluginBridge.get_plugin()
		plugin.env_update.connect(_update_menu_button)

		RivetPluginBridge.instance.bootstrapped.connect(_on_plugin_bootstrapped)

## Recreate environemtns and update selected index.
func _update_menu_button() -> void:
	var plugin = RivetPluginBridge.get_plugin()

	# Insert values
	clear()
	
	if !remote_only:
		add_separator("Local")
		add_item("Local")

		add_separator("Remote")

	for env in environments:
		add_item("%s (%s)" % [env.name, env.slug])
	
	# Add create button
	if plugin.is_authenticated:
		add_item("+ Create Environment")
	else:
		add_item("+ Create Environment (Sign In Required)")

	# Update selected
	if plugin.env_type == _RivetGlobal.EnvType.REMOTE:
		var remote_env_idx = null
		for i in environments.size():
			if environments[i].id == plugin.remote_env_id:
				remote_env_idx = i
				break

		if remote_env_idx != null:
			# Select remote env
			select(remote_env_idx + _envs_idx_offset)
		else:
			# Could not find env
			RivetPluginBridge.warning("_update_menu_button: could not find remote env idx for %s" % plugin.remote_env_id)
			select(-1)
	elif plugin.env_type == _RivetGlobal.EnvType.LOCAL:
		if remote_only:
			# No local env
			select(-1)
		else:
			# Select local
			select(1)

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
		plugin.remote_env_id = environments[idx - _envs_idx_offset].id
	elif idx == environments.size() + _envs_idx_offset:
		_open_create_remote()
	else:
		push_error("Mismatched env menu index %s" % idx)
	RivetPluginBridge.instance.save_configuration()
	
	# Update tooltips
	tooltip_text = "Endpoint: %s" % plugin.backend_endpoint

func _open_create_remote():
	var plugin = RivetPluginBridge.get_plugin()

	# Reset selection to local
	select(0)

	if plugin.is_authenticated:
		# Open create URL
		OS.shell_open("https://hub.rivet.gg/games/" + plugin.cloud_data.game_id + "?modal=create-environment")
	else:
		# Open sign in
		var popup = _SignIn.instantiate()
		add_child(popup)
		popup.popup()

func _on_plugin_bootstrapped() -> void:
	disabled = false
	selected = 0
	_update_menu_button()
