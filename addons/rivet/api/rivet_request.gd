signal completed

const RivetResponse := preload("rivet_response.gd")
const RivetRequest := preload("rivet_request.gd")

var _response: RivetResponse = null
var _opts: Dictionary
var http_request: HTTPRequest

func _init(owner: Node, method: HTTPClient.Method, url: String, opts: Variant = null):
	self.http_request = HTTPRequest.new()
	http_request.request_completed.connect(_on_request_completed)
	_opts = {
		"method": method,
		"url": url,
		"body": opts.body,
		"headers": opts.headers,
	}
	owner.add_child(self.http_request)
	
func request() -> RivetRequest:
	var error = http_request.request(_opts.url, _opts.headers, _opts.method, _opts.body)
	return self

func _on_request_completed(result, response_code, headers, body):
	_response = RivetResponse.new(result, response_code, headers, body)
	completed.emit()

func wait_completed() -> RivetResponse:
	await completed
	return _response

