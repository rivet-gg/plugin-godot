extends Node

var hostname = "127.0.0.1"
var port = 8910
var peer: MultiplayerPeer

@export var player_scene: PackedScene

@export var sync_parent: Node2D

var players: Dictionary = {}

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)

func peer_connected(id):
	print('Peer connected', id)
	
	if multiplayer.is_server():
		add_player(id)

func peer_disconnected(id):
	print('Peer disconnected', id)
	
	if multiplayer.is_server():
		remove_player(id)

func connected_to_server():
	print('Connected to server')

func connection_failed():
	print('Connection failed')

func server_disconnected():
	print('Server disconnected')

func _on_host_button_down():
	host()

func _on_join_button_down():
	join()

func host():
	print('Hosting')

	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port)
	if (error):
		print('Error starting server', error)
		return

	multiplayer.set_multiplayer_peer(peer)
	
	start_game()

func join():
	print('Joining')

	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(hostname, port)
	if (error):
		print('Error creating client', error)
		return
	multiplayer.set_multiplayer_peer(peer)
	
	start_game()

func start_game():
	if multiplayer.is_server():
		add_player(multiplayer.get_unique_id())
	$CanvasLayer.hide()
	pass

func add_player(id: int):
	print('Adding player', id)
	var player = player_scene.instantiate()
	player.name = str(id)
	players[id] = player
	sync_parent.call_deferred("add_child", player)
	
func remove_player(id: int):
	var player = players[id]
	if player != null:
		print("Player removed", id)
		sync_parent.call_deferred("remove_child", player)
	else:
		print("Player is null", id)
