# This file is auto-generated by the Rivet (https://rivet.gg) build system.
# 
# Do not edit this file directly.

extends RefCounted
class_name RivetRequest
## A wrapper around HTTPRequest that emits a signal when the request is completed.
## This is a workaround for the fact that `HTTPRequest.request()` is blocking.
## To run a request, create a new Request, connect to the completed signal,
## and call `request().wait_completed()` to wait for the request to complete.

const _ApiResponse := preload("response.gd")

var _started_at: int
var _method: HTTPClient.Method
var _url: String

## Human-friendly string indicating what this request does. This helps make it
## more clear what the request is doing in the logs instead of a verbose URL.
var _request_name = null

var response: _ApiResponse = null
var _opts: Dictionary
var _http_request: HTTPRequest

var _success_callback: Callable
var _failure_callback: Callable

signal completed(response: _ApiResponse)
signal succeeded(response: _ApiResponse)
signal failed(response: _ApiResponse)

func _init(owner: Node, method: HTTPClient.Method, url: String, opts: Variant = {}):
	self._started_at = Time.get_ticks_msec()
	self._method = method
	self._url = url
	if "request_name" in opts:
		_request_name = opts.request_name

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

func set_success_callback(callback: Callable) -> RivetRequest:
	self._success_callback = callback
	return self

func set_failure_callback(callback: Callable) -> RivetRequest:
	self._failure_callback = callback
	return self

func _on_request_completed(result, response_code, headers, body):
	self.response = _ApiResponse.new(result, response_code, headers, body)

	var finished_at = Time.get_ticks_msec()
	var elapsed = finished_at - self._started_at

	# Print request
	var log_str
	var is_error= false

	if _request_name != null:
		log_str = "request=%s" % _request_name
	else:
		log_str = "request=%s" % _url

	if response.response_code == 200 && response.body != null:
		log_str += " result=ok"
	elif (response.response_code == 400 || response.response_code == 500) && response.body != null && "message" in response.body:
		if "code" in response.body:
			log_str += " result=%s" % response.body.code
		else:
			log_str += " result=unknown_error"
		if "module" in response.body:
			log_str += " module=%s" % response.body.module
		log_str += " message=\"%s\"" % response.body.message
		if "meta" in response.body:
			log_str += " meta=%s" % JSON.stringify(response.body.meta)
	else:
		is_error = true
		log_str += " result=%s http_status=%s response_code=%s" % [
			RivetResponse.Result.keys()[response.result],
			response.http_status,
			response.response_code,
		]

	log_str += " elapsed=%sms" % elapsed

	if is_error:
		RivetLogger.error(log_str)
	else:
		RivetLogger.log(log_str)

	# Callbacks
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
func async() -> _ApiResponse:
	await completed
	return response
