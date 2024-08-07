# This file is auto-generated by the Open Game Backend (https://opengb.dev) build system.
# 
# Do not edit this file directly.
#
# Generated at 2024-07-18T12:12:50.297Z

extends Node
class_name BackendSingleton
# API for interacting with the backend.

const _Client = preload("client/client.gd")
const _Configuration = preload("client/configuration.gd")

## Client used to connect o the backend.
var client: _Client

## Configuration for how to connect to the backend.
var configuration: _Configuration

func _init():
	self.configuration = _Configuration.new()

	self.client = _Client.new(self.configuration)
	self.add_child(self.client)

	self._init_modules()

const _BackendUsers := preload("modules/users.gd")

const _BackendRateLimit := preload("modules/rate_limit.gd")

const _BackendTokens := preload("modules/tokens.gd")

const _BackendLobbies := preload("modules/lobbies.gd")

const _BackendRivet := preload("modules/rivet.gd")



var users: _BackendUsers

var rate_limit: _BackendRateLimit

var tokens: _BackendTokens

var lobbies: _BackendLobbies

var rivet: _BackendRivet



func _init_modules():

	self.users = _BackendUsers.new(self.client)

	self.rate_limit = _BackendRateLimit.new(self.client)

	self.tokens = _BackendTokens.new(self.client)

	self.lobbies = _BackendLobbies.new(self.client)

	self.rivet = _BackendRivet.new(self.client)





