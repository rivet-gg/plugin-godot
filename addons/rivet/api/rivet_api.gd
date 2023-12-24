class_name RivetApi
const RivetRequest = preload("rivet_request.gd")

static func _get_api_url():
	return RivetDevtools.get_plugin().api_endpoint

## Gets the authorization token from the environment or from a config file
static func _get_cloud_token():
	var plugin = RivetDevtools.get_plugin()
	if plugin:
		return plugin.cloud_token

	# TODO: get it from config file if local
	var token_env = OS.get_environment("RIVET_TOKEN")
	assert(!token_env.is_empty(), "missing RIVET_TOKEN environment")
	return token_env

static func _get_namespace_token():
	var plugin = RivetDevtools.get_plugin()
	if plugin:
		return plugin.namespace_token
	
	# TODO: get it from somewhere else, prefferably CLI
	assert(false, "missing NAMESPACE_TOKEN")

## Builds the headers for a request, including the authorization token
static func _build_headers(service: String) -> PackedStringArray:
	var token = _get_cloud_token() if service == "cloud" else _get_namespace_token()
	return [
		"Authorization: Bearer " + token,
	]

## Builds a URL to Rivet cloud services
static func _build_url(path: String, service: String) -> String:
	var path_segments := path.split("/", false)
	path_segments.remove_at(0)
	return _get_api_url() + service + "/" + "/".join(path_segments)

## Gets service name from a path (e.g. /users/123 -> users)
static func _get_service_from_path(path: String) -> String:
	var path_segments := path.split("/", false)
	return path_segments[0]

## Creates a POST request to Rivet cloud services
## @experimental
static func POST(owner: Node, path: String, body: Dictionary) -> RivetRequest:
	var service := _get_service_from_path(path)
	var url := _build_url(path, service)
	var body_json := JSON.stringify(body)
	
	return RivetRequest.new(owner, HTTPClient.METHOD_POST, url, { 
		"headers": _build_headers(service), 
		"body": body_json
	})

## Creates a GET request to Rivet cloud services
## @experimental
static func GET(owner: Node, path: String, body: Dictionary) -> RivetRequest:
	var service := _get_service_from_path(path)
	var url := _build_url(path, service)
	var body_json := JSON.stringify(body)
	
	return RivetRequest.new(owner, HTTPClient.METHOD_GET, url, { 
		"headers": _build_headers(service), 
		"body": body_json
	})
