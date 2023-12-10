var result: int
var response_code: int
var headers: PackedStringArray
var body: Dictionary

func _init(result: int, response_code: int, headers: PackedStringArray, response_body: PackedByteArray) -> void:
	self.result = result
	self.response_code = response_code
	self.headers = headers
	
	var json = JSON.new()
	json.parse(response_body.get_string_from_utf8())
	body = json.get_data()
	
