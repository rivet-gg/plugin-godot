# This file is auto-generated by the Open Game Backend (https://opengb.dev) build system.
# 
# Do not edit this file directly.
#
# Generated at 2024-07-18T12:12:50.295Z

class_name BackendLobbies
## Lobbies
## 
## Lobby & player management.

const _ApiResponse := preload("../client/response.gd")

var _client: BackendClient

func _init(client: BackendClient):
	self._client = client

## Create Lobby
## 
## Creates a new lobby on-demand.
func create(body: Dictionary = {}) -> BackendRequest:
	return self._client.build_request(HTTPClient.METHOD_POST, "/modules/lobbies/scripts/create/call", body)

## Destroy Lobby
## 
## Destroys an existing lobby.
func destroy(body: Dictionary = {}) -> BackendRequest:
	return self._client.build_request(HTTPClient.METHOD_POST, "/modules/lobbies/scripts/destroy/call", body)

## Find Or Create Lobby
## 
## Finds a lobby or creates one if there are no available spots for players.
func find_or_create(body: Dictionary = {}) -> BackendRequest:
	return self._client.build_request(HTTPClient.METHOD_POST, "/modules/lobbies/scripts/find_or_create/call", body)

## Join Lobby
## 
## Add a player to an existing lobby.
func join(body: Dictionary = {}) -> BackendRequest:
	return self._client.build_request(HTTPClient.METHOD_POST, "/modules/lobbies/scripts/join/call", body)

## List Lobbies
## 
## List & query all lobbies.
func list(body: Dictionary = {}) -> BackendRequest:
	return self._client.build_request(HTTPClient.METHOD_POST, "/modules/lobbies/scripts/list/call", body)

## Set Lobby Ready
## 
## Called on lobby startup after initiation to notify it can start accepting player. This should be called after operations like loading maps are complete.
func set_lobby_ready(body: Dictionary = {}) -> BackendRequest:
	return self._client.build_request(HTTPClient.METHOD_POST, "/modules/lobbies/scripts/set_lobby_ready/call", body)

## Set Player Connected
## 
## Called when a player connects to the lobby.
func set_player_connected(body: Dictionary = {}) -> BackendRequest:
	return self._client.build_request(HTTPClient.METHOD_POST, "/modules/lobbies/scripts/set_player_connected/call", body)

## Set Player Disconnected
## 
## Called when a player disconnects from the lobby.
func set_player_disconnected(body: Dictionary = {}) -> BackendRequest:
	return self._client.build_request(HTTPClient.METHOD_POST, "/modules/lobbies/scripts/set_player_disconnected/call", body)

## Find Lobby
## 
## Finds an existing lobby with a given query. This will not create a new lobby, see `find_or_create` instead.
func find(body: Dictionary = {}) -> BackendRequest:
	return self._client.build_request(HTTPClient.METHOD_POST, "/modules/lobbies/scripts/find/call", body)



