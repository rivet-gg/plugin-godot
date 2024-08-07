extends BackendMultiplayerManager

const player_scene = preload("player.tscn")

# Anything inside this node is synchronized
@onready var sync_parent: Node2D = %Synchronized

@onready var menu: Node = %Menu

var players: Dictionary = {}

func _ready():
	setup_multiplayer()

	self.server_connected.connect(_on_server_connected)
	self.client_connected.connect(_on_client_connected)
	self.client_disconnected.connect(_on_client_disconnected)

# Called on only the client
func _on_server_connected():
	print('Server connected')
	menu.hide()

# Called on only the server
func _on_client_connected(id: int):
	print('Client connected %s' % id)
	
	var player = player_scene.instantiate()
	player.name = str(id)
	players[id] = player
	sync_parent.call_deferred("add_child", player)

# Called on only the server
func _on_client_disconnected(id: int):
	print('Client disconnected %s' % id)

	var player = players[id]
	if player != null:
		players.erase(id)
		print("Player removed %s" % id)
		sync_parent.call_deferred("remove_child", player)

func _on_find_lobby_pressed():
	# Get or create a lobby from the backend
	var response = await Backend.lobbies.find_or_create({
		# "version": Backend.configuration.game_version,
		# "regions": ["atl"],
		"version": "default",
	"regions": ["local"],
		"tags": {},
		"players": [{}],
		"createConfig": {
			"region": "atl",
			"tags": {},
			"maxPlayers": 32,
			"maxPlayersDirect": 32,
		}
	}).async()

	# Open a network connection to the server
	if response.is_ok():
		connect_to_lobby(response.body.lobby, response.body.players[0])
