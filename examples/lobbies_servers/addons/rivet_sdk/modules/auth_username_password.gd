# This file is auto-generated by the Rivet (https://rivet.gg) build system.
# 
# Do not edit this file directly.

class_name RivetAuthUsernamePassword
## Auth Username Password
## 
## Authenticate users with a username/password combination.

const _ApiResponse := preload("../client/response.gd")

var _client: RivetClient

func _init(client: RivetClient):
	self._client = client

## Sign Up with Username and Password
## 
## Sign up a new user with a username and password.
func sign_up(body: Dictionary = {}) -> RivetRequest:
	return self._client.build_request(HTTPClient.METHOD_POST, "/modules/auth_username_password/scripts/sign_up/call", body)

## Sign In with Username and Password
## 
## Sign in a user with a username and password.
func sign_in(body: Dictionary = {}) -> RivetRequest:
	return self._client.build_request(HTTPClient.METHOD_POST, "/modules/auth_username_password/scripts/sign_in/call", body)


