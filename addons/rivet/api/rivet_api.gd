class_name RivetApi
const RivetRequest = preload("rivet_request.gd")

static var CONFIGURATION_CACHE

static func _get_configuration():
	if CONFIGURATION_CACHE:
		return CONFIGURATION_CACHE

	if FileAccess.file_exists(RivetPluginBridge.RIVET_CONFIGURATION_FILE_PATH):
		var config_file = ResourceLoader.load(RivetPluginBridge.RIVET_CONFIGURATION_FILE_PATH)
		if config_file and 'new' in config_file:
			CONFIGURATION_CACHE = config_file.new()
			return CONFIGURATION_CACHE

	if FileAccess.file_exists(RivetPluginBridge.RIVET_DEPLOYED_CONFIGURATION_FILE_PATH):
		var deployed_config_file = ResourceLoader.load(RivetPluginBridge.RIVET_DEPLOYED_CONFIGURATION_FILE_PATH)
		if deployed_config_file and 'new' in deployed_config_file:
			CONFIGURATION_CACHE = deployed_config_file.new()
			return CONFIGURATION_CACHE

	push_warning("Rivet configuration file not found")
	CONFIGURATION_CACHE = null
	return CONFIGURATION_CACHE

static func _get_api_url():
	var plugin = RivetPluginBridge.get_plugin()
	if plugin:
		return plugin.api_endpoint

	var config = _get_configuration()
	if config:
		return config.api_endpoint

	var url_env = OS.get_environment("RIVET_API_ENDPOINT")
	if url_env:
		return url_env
	return "https://api.rivet.gg"

## Gets the authorization token from the environment or from a config file
static func _get_cloud_token():
	var plugin = RivetPluginBridge.get_plugin()
	if plugin:
		return plugin.cloud_token

	var config = _get_configuration()
	if config:
		return config.cloud_token

	var token_env = OS.get_environment("RIVET_TOKEN")
	assert(!token_env.is_empty(), "missing RIVET_TOKEN environment")
	return token_env

static func _get_namespace_token():
	var plugin = RivetPluginBridge.get_plugin()
	if plugin:
		return plugin.namespace_token

	var config = _get_configuration()
	if config:
		return config.namespace_token
	
	var token_env = OS.get_environment("NAMESPACE_TOKEN")
	assert(!token_env.is_empty(), "missing NAMESPACE_TOKEN environment")
	return token_env

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
	return _get_api_url() + "/%s/%s" % [service, "/".join(path_segments)]

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
