# This file is auto-generated by the Rivet (https://rivet.gg) build system.
# 
# Do not edit this file directly.

class_name RivetUserPasswords
## User Password Verifier
## 
## An INTERNAL-ONLY module to store and verify passwords by user ID. Used by some auth modules that require password verification.

const _ApiResponse := preload("../client/response.gd")

var _client: RivetClient

func _init(client: RivetClient):
	self._client = client



