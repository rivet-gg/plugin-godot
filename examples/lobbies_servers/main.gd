extends BackendMultiplayerManager

@export var player_scene: PackedScene
@export var sync_parent: Node2D

@onready var _version_label = %VersionLabel

var players: Dictionary = {}

func _ready():
	setup_multiplayer()

	self.server_connected.connect(_on_server_connected)
	self.client_connected.connect(_on_client_connected)
	self.client_disconnected.connect(_on_client_disconnected)

	_version_label.text = 'Game Version: %s' % Backend.configuration.game_version

func _on_server_connected():
	print('Server connected')
	$CanvasLayer.hide()

func _on_client_connected(id: int):
	print('Client connected %s' % id)
	
	var player = player_scene.instantiate()
	player.name = str(id)
	players[id] = player
	sync_parent.call_deferred("add_child", player)

func _on_client_disconnected(id: int):
	print('Client disconnected %s' % id)

	var player = players[id]
	if player != null:
		players.erase(id)
		print("Player removed %s" % id)
		sync_parent.call_deferred("remove_child", player)
	else:
		print("Player is null %s" % id)

func _on_find_lobby_pressed():
	var response = await Backend.lobbies.find_or_create({
		"version": Backend.configuration.game_version,
		"regions": ["atl"],
		"tags": {"foo": "b"},
		"players": [{}],
		"createConfig": {
			"region": "atl",
			"tags": {"foo": "b"},
			"maxPlayers": 32,
			"maxPlayersDirect": 32,
		}
	}).async()
	if response.is_ok():
		connect_to_lobby(response.body.lobby, response.body.players[0])
