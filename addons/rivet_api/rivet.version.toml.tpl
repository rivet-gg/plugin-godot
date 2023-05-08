# === Rivet Version Configuration ===
# 
# - More info: https://docs.rivet.gg/general/concepts/rivet-version-config
# - Reference: https://docs.rivet.gg/cloud/api/post-games-versions#body
# - Publish a new version with `rivet publish`
#

# How the game lobbies run and how players connect to the game.
#
# https://docs.rivet.gg/matchmaker/introduction
[matchmaker]
	# How many players can join a specific lobby.
	#
	# Read more about matchmaking: https://docs.rivet.gg/matchmaker/concepts/finding-lobby
	max_players = 32

	# The hardware to provide for lobbies.
	#
	# Available tiers: https://docs.rivet.gg/serverless-lobbies/concepts/available-tiers
	tier = "basic-1d1"

# Which regions the game should be available in.
#
# Available regions: https://docs.rivet.gg/serverless-lobbies/concepts/available-regions
[matchmaker.regions]
	lnd-sfo = {}
	lnd-fra = {}

# Runtime configuration for the lobby's Docker container.
[matchmaker.docker]
	# If you're unfamiliar with Docker, here's how to write your own
	# Dockerfile:
	# https://docker-curriculum.com/#dockerfile
	dockerfile = "Dockerfile"

	# Which ports to allow players to connect to. Multiple ports can be defined
	# with different protocols.
	#
	# How ports work: https://docs.rivet.gg/serverless-lobbies/concepts/ports
	ports.default = { port = 10567, protocol = "udp" }

# What game modes are avaiable.
#
# Properties like `max_players`, `tier`, `dockerfile`, `regions`, and more can
# be overriden for specific game modes.
[matchmaker.game_modes]
	default = {}

[kv]

[identity]

