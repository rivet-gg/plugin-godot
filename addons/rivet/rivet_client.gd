## @deprecated
extends Node

var base_url = "https://api.rivet.gg/v1"

## @deprecated
func get_token():
	var token_env = OS.get_environment("RIVET_TOKEN")
	assert(!token_env.is_empty(), "missing RIVET_TOKEN environment")
	return token_env
	
## @deprecated
func lobby_ready(body: Variant, on_success: Callable, on_fail: Callable):
	_rivet_request_with_body("POST", "matchmaker", "/lobbies/ready", body, on_success, on_fail)

## @deprecated
func find_lobby(body: Variant, on_success: Callable, on_fail: Callable):
	_rivet_request_with_body("POST", "matchmaker", "/lobbies/find", body, on_success, on_fail)

## @deprecated
func player_connected(body: Variant, on_success: Callable, on_fail: Callable):
	_rivet_request_with_body("POST", "matchmaker", "/players/connected", body, on_success, on_fail)

## @deprecated
func player_disconnected(body: Variant, on_success: Callable, on_fail: Callable):
	_rivet_request_with_body("POST", "matchmaker", "/players/disconnected", body, on_success, on_fail)

func _build_url(service, path) -> String:
	return base_url.replace("://", "://" + service + ".") + path

func _build_headers() -> PackedStringArray:
	return [
		"Authorization: Bearer " + get_token(),
	]
	
## @deprecated
func _rivet_request(method: String, service: String, path: String, on_success: Callable, on_fail: Callable):
	var url = _build_url(service, path)
	RivetHelper.rivet_print("%s %s" % [method, url])
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed.bind(on_success, on_fail))

	var error = http_request.request(url, _build_headers())
	if error != OK:
		push_error("An error occurred in the HTTP request.")
		if on_fail != null:
			on_fail.call("Request failed to send: %s" % error)

## @deprecated
func _rivet_request_with_body(method: String, service: String, path: String, body: Variant, on_success: Callable, on_fail: Callable):
	var url = _build_url(service, path)
	RivetHelper.rivet_print("%s %s: %s" % [method, url, body])

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed.bind(on_success, on_fail))

	var body_json = JSON.stringify(body)
	var error = http_request.request(url, _build_headers(), HTTPClient.METHOD_POST, body_json)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
		if on_fail != null:
			on_fail.call("Request failed to send: %s" % error)

## @deprecated
func _http_request_completed(result, response_code, _headers, body, on_success: Callable, on_fail: Callable):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Request error ", result)
		if on_fail != null:
			on_fail.call("Request error: %s" % result)
		return
		
	RivetHelper.rivet_print("%s: %s" % [response_code, body.get_string_from_utf8()])

	if response_code != 200:
		push_error("Request failed ", response_code, " ", body.get_string_from_utf8())
		if on_fail != null:
			on_fail.call("Request failed (%s): %s" % [response_code, body.get_string_from_utf8()])
		return

	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	if on_success != null:
		on_success.call(response)

