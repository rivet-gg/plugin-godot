extends RefCounted
## A wrapper around HTTPRequest that emits a signal when the request is completed.
## This is a workaround for the fact that `HTTPRequest.request()` is blocking.
## To run a request, create a new RivetRequest, connect to the completed signal,
## and call `request().wait_completed()` to wait for the request to complete.


const _RivetResponse := preload("rivet_response.gd")
const _RivetRequest := preload("rivet_request.gd")

var response: _RivetResponse = null
var _opts: Dictionary
var _http_request: HTTPRequest

var _success_callback: Callable
var _failure_callback: Callable

signal completed(response: _RivetResponse)
signal succeeded(response: _RivetResponse)
signal failed(response: _RivetResponse)

func _init(owner: Node, method: HTTPClient.Method, url: String, opts: Variant = null):
	self._http_request = HTTPRequest.new()
	self._http_request.request_completed.connect(_on_request_completed)
	self._opts = {
		"method": method,
		"url": url,
		"body": opts.body,
		"headers": opts.headers,
	}
	owner.add_child(self._http_request)
	self._http_request.request(_opts.url, _opts.headers, _opts.method, _opts.body)

func set_success_callback(callback: Callable) -> _RivetRequest:
	self._success_callback = callback
	return self

func set_failure_callback(callback: Callable) -> _RivetRequest:
	self._failure_callback = callback
	return self

func _on_request_completed(result, response_code, headers, body):
	self.response = _RivetResponse.new(result, response_code, headers, body)
	if result == OK:
		succeeded.emit(response)
		if self._success_callback:
			self._success_callback.call(response)
	else:
		failed.emit(response)
		if self._failure_callback:
			self._failure_callback.call(response)
	completed.emit(response)

## Waits for the request to complete and returns the response in non-blocking way
func wait_completed() -> _RivetResponse:
	await completed
	return response
