extends RefCounted
## A wrapper around HTTPRequest that emits a signal when the request is completed.
## This is a workaround for the fact that `HTTPRequest.request()` is blocking.
## To run a request, create a new RivetRequest, connect to the completed signal,
## and call `request().wait_completed()` to wait for the request to complete.

signal completed

const _RivetResponse := preload("rivet_response.gd")
const _RivetRequest := preload("rivet_request.gd")

var _response: _RivetResponse = null
var _opts: Dictionary
var _http_request: HTTPRequest


func _init(owner: Node, method: HTTPClient.Method, url: String, opts: Variant = null):
	self._http_request = HTTPRequest.new()
	_http_request.request_completed.connect(_on_request_completed)
	_opts = {
		"method": method,
		"url": url,
		"body": opts.body,
		"headers": opts.headers,
	}
	owner.add_child(self._http_request)

## Runs the request
func request() -> _RivetRequest:
	var error = _http_request.request(_opts.url, _opts.headers, _opts.method, _opts.body)
	return self

func _on_request_completed(result, response_code, headers, body):
	_response = _RivetResponse.new(result, response_code, headers, body)
	completed.emit()

## Waits for the request to complete and returns the response in non-blocking way
func wait_completed() -> _RivetResponse:
	await completed
	return _response

