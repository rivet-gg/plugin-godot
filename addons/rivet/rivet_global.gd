
extends Node
## Rivet [/br]
## Mainpoint of the Rivet plugin.
## It includes an easy access to APIs, helpers and tools. [/br]
## @tutorial: https://rivet.gg/learn/godot
## @experimental

const _api = preload("api/rivet_api.gd")

const ApiResponse = preload("api/rivet_response.gd")
const ApiRequest = preload("api/rivet_request.gd")

const _Packages = preload("api/rivet_packages.gd")

var cloud_token: String
var namespace_token: String 
var game_id: String
var api_endpoint: String

var matchmaker: _Packages.Matchmaker = _Packages.Matchmaker.new()

# This variable is only accessible from editor's scripts, please do not use it in your game.
var cli

## @experimental
func POST(path: String, body: Dictionary) -> _api.RivetRequest:
	return _api.POST(self, path, body)

## @experimental
func GET(path: String, body: Dictionary = {}) -> _api.RivetRequest:
	return _api.GET(self, path, body)

## @experimental
func PUT(path: String, body: Dictionary = {}) -> _api.RivetRequest:
	return _api.PUT(self, path, body)
