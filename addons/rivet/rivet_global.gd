## @experimental
extends Node

const _api = preload("api/rivet_api.gd")

## @experimental
func POST(path: String, body: Dictionary) -> _api.RivetRequest:
	return _api.POST(self, path, body)

## @experimental
func GET(path: String, body: Dictionary) -> _api.RivetRequest:
	return _api.GET(self, path, body)
