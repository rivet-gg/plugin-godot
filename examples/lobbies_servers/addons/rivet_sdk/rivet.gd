# This file is auto-generated by the Open Game Backend (https://opengb.dev) build system.
# 
# Do not edit this file directly.
#
# Generated at 2024-09-10T10:37:15.786Z

extends Node
class_name RivetSingleton
# API for interacting with modules.

const _Client = preload("client/client.gd")
const _Configuration = preload("client/configuration.gd")

## Client used to connect to the backend.
var client: _Client

## Configuration for how to connect to the backend.
var configuration: _Configuration

func _init():
	self.configuration = _Configuration.new()

	self.client = _Client.new(self.configuration)
	self.add_child(self.client)

	self._init_modules()

const _RivetUsers := preload("modules/users.gd")

const _RivetRateLimit := preload("modules/rate_limit.gd")

const _RivetTokens := preload("modules/tokens.gd")

const _RivetLobbies := preload("modules/lobbies.gd")

const _RivetRivet := preload("modules/rivet.gd")



var users: _RivetUsers

var rate_limit: _RivetRateLimit

var tokens: _RivetTokens

var lobbies: _RivetLobbies

var rivet: _RivetRivet



func _init_modules():

	self.users = _RivetUsers.new(self.client)

	self.rate_limit = _RivetRateLimit.new(self.client)

	self.tokens = _RivetTokens.new(self.client)

	self.lobbies = _RivetLobbies.new(self.client)

	self.rivet = _RivetRivet.new(self.client)