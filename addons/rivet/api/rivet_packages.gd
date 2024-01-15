const _RivetResponse = preload("rivet_response.gd")

## Lobbies
## @experimental
class Lobbies:
	## Finds a lobby based on the given criteria. If a lobby is not found and
	## prevent_auto_create_lobby is true, a new lobby will be created.
	##
	## [url]{https://rivet.gg/docs/matchmaker/api/lobbies/find}[/url]
	func find(body: Dictionary = {}):
		return await Rivet.POST("matchmaker/lobbies/find", body).wait_completed()

	## Joins a specific lobby. This request will use the direct player count
	## configured for the lobby group.
	##
	## [url]{https://rivet.gg/docs/matchmaker/api/lobbies/join}[/url]
	func join(body: Dictionary = {}) -> _RivetResponse:
		return await Rivet.POST("matchmaker/lobbies/join", body).wait_completed()

	## Marks the current lobby as ready to accept connections. Players will not
	## be able to connect to this lobby until the lobby is flagged as ready.
	##
	## [url]{https://rivet.gg/docs/matchmaker/api/lobbies/ready}[/url]
	func ready(body: Dictionary = {}) -> _RivetResponse:
		return await Rivet.POST("matchmaker/lobbies/ready", body).wait_completed()

	## If is_closed is true, the matchmaker will no longer route players to the 
	## lobby. Players can still join using the /join endpoint (this can be disabled
	## by the developer by rejecting all new connections after setting the lobby
	## to closed). Does not shutdown the lobby.
	##
	## [url]{https://rivet.gg/docs/matchmaker/api/lobbies/set-closed}[/url]
	func setClosed(body: Dictionary = {}) -> _RivetResponse:
		return await Rivet.PUT("matchmaker/lobbies/set_closed", body).wait_completed()

	## Creates a custom lobby.
	##
	## [url]{https://rivet.gg/docs/matchmaker/api/lobbies/create}[/url]
	func create(body: Dictionary = {}) -> _RivetResponse:
		return await Rivet.POST("matchmaker/lobbies/create", body).wait_completed()

	## Lists all open lobbies.
	##
	## [url]{https://rivet.gg/docs/matchmaker/api/lobbies/list}[/url]
	func list(body: Dictionary = {}) -> _RivetResponse:
		return await Rivet.GET("matchmaker/lobbies/list", body).wait_completed()

	## 
	##
	## [url]{https://rivet.gg/docs/matchmaker/api/lobbies/set-state}[/url]
	func setState(body: Dictionary = {}) -> _RivetResponse:
		return await Rivet.PUT("matchmaker/lobbies/state", body).wait_completed()

	## 
	##
	## [url]{https://rivet.gg/docs/matchmaker/api/lobbies/get-state}[/url]
	func getState(lobby_id, body: Dictionary = {}) -> _RivetResponse:
		return await Rivet.GET("matchmaker/lobbies/{lobby_id}/state".format({"lobby_id": lobby_id}), body).wait_completed()

## Players
## @experimental
class Players:
	## Validates the player token is valid and has not already been consumed then
	## marks the player as connected.
	## 
	## [url]{https://rivet.gg/docs/matchmaker/api/players/connected}[/url]
	func connected(body: Dictionary = {}) -> _RivetResponse:
		return await Rivet.POST("matchmaker/players/connected", body).wait_completed()

	## Marks a player as disconnected. # Ghost Players.
	##
	## [url]{https://rivet.gg/docs/matchmaker/api/players/disconnected}[/url]
	func disconnected(body: Dictionary = {}) -> _RivetResponse:
		return await Rivet.POST("matchmaker/players/disconnected", body).wait_completed()

	## Gives matchmaker statistics about the players in game.
	##
	## [url]{https://rivet.gg/docs/matchmaker/api/players/statistics}[/url]
	func getStatistics(body: Dictionary = {}) -> _RivetResponse:
		return await Rivet.GET("matchmaker/players/statistics", body).wait_completed()

class Regions:
	## Returns a list of regions available to this namespace.
	## Regions are sorted by most optimal to least optimal. 
	## The player's IP address is used to calculate the regions' optimality.
	##
	## [url]{https://rivet.gg/docs/matchmaker/api/regions/list}[/url]
	func list(body: Dictionary = {}) -> _RivetResponse:
		return await Rivet.GET("matchmaker/regions", body).wait_completed()

## Matchmaker
## @experimental
## @tutorial: https://rivet.gg/docs/matchmaker
class Matchmaker:
	static var lobbies: Lobbies = Lobbies.new()
	static var players: Players = Players.new()
	static var regions: Regions = Regions.new()
