# This file is auto-generated by the Open Game Backend (https://opengb.dev) build system.
# 
# Do not edit this file directly.
#
# Generated at 2024-07-18T12:12:50.297Z

class_name BackendRivet
## Rivet API
## 
## Helper for calling the Rivet API.

const _ApiResponse := preload("../client/response.gd")

var _client: BackendClient

func _init(client: BackendClient):
	self._client = client



