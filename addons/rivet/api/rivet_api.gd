class_name RivetApi
const RivetRequest = preload("rivet_request.gd")

static func _get_api_url():
	return "https://api.staging2.gameinc.io/%s"

## Gets the authorization token from the environment or from a config file
static func _get_token():
	# TODO: get it from config file if local
	var token_env = OS.get_environment("RIVET_TOKEN")
	assert(!token_env.is_empty(), "missing RIVET_TOKEN environment")
	return token_env

## Builds the headers for a request, including the authorization token
static func _build_headers() -> PackedStringArray:
	return [
		"Authorization: Bearer " + _get_token(),
	]

## Builds a URL to Rivet cloud services
static func _build_url(path: String) -> String:
	var path_segments := path.split("/")
	var service = path_segments[0]
	path_segments.remove_at(0)
	return (_get_api_url() % service) + "/".join(path_segments)

## Creates a POST request to Rivet cloud services
## @experimental
static func POST(owner: Node, path: String, body: Dictionary) -> RivetRequest:
	var url = _build_url(path)
	var body_json := JSON.stringify(body)
	
	return RivetRequest.new(owner, HTTPClient.METHOD_POST, url, { 
		"headers": _build_headers(), 
		"body": body_json
	})

## Creates a GET request to Rivet cloud services
## @experimental
static func GET(owner: Node, path: String, body: Dictionary) -> RivetRequest:
	var url = _build_url(path)
	var body_json := JSON.stringify(body)
	
	return RivetRequest.new(owner, HTTPClient.METHOD_GET, url, { 
		"headers": _build_headers(), 
		"body": body_json
	})
