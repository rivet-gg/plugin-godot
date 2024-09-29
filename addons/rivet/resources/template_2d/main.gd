extends RivetMultiplayerManager

const player_scene = preload("player.tscn")

# Anything inside this node is synchronized
@onready var sync_parent: Node2D = %Synchronized

@onready var menu: Node = %Menu

var players: Dictionary = {}

func _ready():
	# Setup multiplayer
	setup_multiplayer()
	self.server_connected.connect(_on_server_connected)
	self.server_disconnected.connect(_on_server_disconnected)
	self.client_connected.connect(_on_client_connected)
	self.client_disconnected.connect(_on_client_disconnected)
	
	# Setup menu
	if !is_server:
		_update_ui_status("Idle")
		_fetch_regions()

# === Multiplayer ===
# Called on only the client
func _on_server_connected():
	_update_ui_status("Connected")
	menu.hide()
	
# Called on only the client
func _on_server_disconnected():
	_update_ui_status("Disconnected")
	menu.show()

# Called on only the server
func _on_client_connected(id: int):
	var player = player_scene.instantiate()
	player.name = str(id)
	players[id] = player
	sync_parent.call_deferred("add_child", player)

# Called on only the server
func _on_client_disconnected(id: int):
	var player = players[id]
	if player != null:
		players.erase(id)
		print("Player removed %s" % id)
		sync_parent.call_deferred("remove_child", player)

# === UI===
var regions_data = null
var find_data = null

func _update_ui_status(status: String):
	var text = "[b]Status[/b] %s\n" % status
	text += "[b]Game Version[/b] %s\n" % Rivet.configuration.game_version
	text += "[b]Transport[/b] %s\n" % Transport.keys()[transport]
	if find_data != null:
		if find_data.is_ok():
			text += "[b]Lobby ID[/b] %s\n" % find_data.body.lobby.id
			text += "[b]Lobby Tags[/b] %s\n" % JSON.stringify(find_data.body.lobby.tags)
			text += "[b]Region[/b] %s\n" % find_data.body.lobby.region.name
		else:
			text += "[b]Find Error[/b] %s\n" % JSON.stringify(find_data.body)
	%LobbyStatus.text = text

func _fetch_regions():
	# Select a region
	regions_data = await Rivet.lobbies.list_regions({}).async()
	if !regions_data.is_ok():
		return
		
	# Update UI
	%RegionOption.clear()
	for region in regions_data.body.regions:
		%RegionOption.add_item(region.name)

func _on_find_lobby_pressed():
	# Find a lobby
	_update_ui_status("Waiting For Lobby")
	menu.hide()
	var region = regions_data.body.regions[%RegionOption.selected].slug
	find_data = await Rivet.lobbies.find_or_create({
		"version": Rivet.configuration.game_version,
		"regions": [region],
		"tags": {},
		"players": [{}],
		"createConfig": {
			"region": region,
			"tags": {},
			"maxPlayers": 32,
			"maxPlayersDirect": 32,
		}
	}).async()
	if !find_data.is_ok():
		_update_ui_status("Find Lobby Failed (See Logs)")
		menu.show()
		return

	# Open a network connection to the server
	_update_ui_status("Connecting")
	connect_to_lobby(find_data.body.lobby, find_data.body.players[0])

