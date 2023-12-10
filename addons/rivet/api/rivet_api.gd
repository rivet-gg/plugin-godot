const RivetRequest = preload("rivet_request.gd")

static var base_url = "https://api.staging2.gameinc.io/%s"

static func _get_token():
	# TODO: get it from config file if local
	var token_env = OS.get_environment("RIVET_TOKEN")
	assert(!token_env.is_empty(), "missing RIVET_TOKEN environment")
	return token_env
	#return YOUR_TOKEN

static func _build_headers() -> PackedStringArray:
	return [
		"Authorization: Bearer " + _get_token(),
	]
	
static func _build_url(path: String) -> String:
	var path_segments := path.split("/")
	var service = path_segments[0]
	path_segments.remove_at(0)
	return base_url % service + "/".join(path_segments)

## @experimental
static func POST(owner: Node, path: String, body: Dictionary) -> RivetRequest:
	var url = _build_url(path)
	var body_json := JSON.stringify(body)
	
	return RivetRequest.new(owner, HTTPClient.METHOD_POST, url, { 
		"headers": _build_headers(), 
		"body": body_json
	})

## @experimental
static func GET(owner: Node, path: String, body: Dictionary) -> RivetRequest:
	var url = _build_url(path)
	var body_json := JSON.stringify(body)
	
	return RivetRequest.new(owner, HTTPClient.METHOD_GET, url, { 
		"headers": _build_headers(), 
		"body": body_json
	})
