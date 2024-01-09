extends RefCounted
## It's a wrapper for the output of the command line tools

var exit_code: ExitCode
var output: Dictionary
var formatted_output: Array = []

## The exit code of the command line tool
enum ExitCode {
	SUCCESS = 0
	# TODO: fill with the rest of the exit codes
}

func _init(exit_code: int, internal_output: Array) -> void:
	self.exit_code = exit_code

	if internal_output and not internal_output.is_empty():
		_parse_output(internal_output)

func _parse_output(internal_output: Array) -> void:
	self.formatted_output = internal_output.map(
		func (line: String): 
			# TODO(compat): test this on windows as it may have different EOFs
			return line.split("\n", false)
	).reduce(
		func (accum, line): 
			accum.append_array(line) 
			return accum
	,[])

	var lines_with_json = self.formatted_output.filter(
		func (line: String): 
			return line.find("{") != -1
	)

	if lines_with_json.is_empty():
		print("No JSON output found")
		return

	var line_with_json: String = lines_with_json.front()
	# Parse the output as JSON
	var json: JSON = JSON.new()
	var error: Error = json.parse(line_with_json)

	if error == OK:
		self.output = json.data
	else:
		# If the output is not JSON, throw an error
		print("Error parsing JSON output: " + str(error))
