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
	# Use plugin config if available
	var plugin = RivetPluginBridge.get_plugin()
	if plugin:
		return plugin.api_endpoint

	# Override shipped configuration endpoint
	var url_env = OS.get_environment("RIVET_API_ENDPOINT")
	if url_env:
		return url_env

	# Use configuration shipped with game
	var config = _get_configuration()
	if config:
		return config.api_endpoint
	
	# Fallback
	return "https://api.rivet.gg"

## Get authorization token used from within only the plugin for cloud-specific
## actions.
static func _get_cloud_token():
	# Use plugin config if available
	var plugin = RivetPluginBridge.get_plugin()
	if plugin:
		return plugin.cloud_token

	OS.crash("Rivet cloud token not found, this should only be called within the plugin")

## Get authorization token used for making requests from within the game.
##
## The priority of tokens is:
##
## - If in editor, use the plugin token
## - If provided by environment, then use that (allows for testing)
## - Assume config is provided by the game client
static func _get_runtime_token():
	# Use plugin config if available
	var plugin = RivetPluginBridge.get_plugin()
	if plugin:
		return plugin.namespace_token

	# Use configuration shipped with game
	var token_env = OS.get_environment("RIVET_TOKEN")
	if token_env:
		return token_env

	# Use configuration shipped with game
	var config = _get_configuration()
	if config:
		return config.namespace_token

	OS.crash("Rivet token not found, validate a config is shipped with the game in the .rivet folder")

## Builds the headers for a request, including the authorization token
static func _build_headers(service: String) -> PackedStringArray:
	var token = _get_cloud_token() if service == "cloud" else _get_runtime_token()
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
	
## Creates a PUT request to Rivet cloud services
## @experimental
static func PUT(owner: Node, path: String, body: Dictionary) -> RivetRequest:
	var service := _get_service_from_path(path)
	var url := _build_url(path, service)
	var body_json := JSON.stringify(body)
	
	return RivetRequest.new(owner, HTTPClient.METHOD_PUT, url, { 
		"headers": _build_headers(service), 
		"body": body_json
	})
