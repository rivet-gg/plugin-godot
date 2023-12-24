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

func _init(exit_code: int, output: Array) -> void:
	self.exit_code = exit_code

	# Parse the output as JSON
	var json = JSON.new()
	var error = json.parse(output[0])

	# TODO: this is assuming that only the first line is all the data that will
	# be given back to Godot from the CLI. It would be good to either enforce
	# this somehow, or have a better mechanism for handling potentially multiple
	# lines in Godot. I'd opt for the former, since it will mean less work in
	# other engines as well.

	if error == OK:
		self.output = json.data
	else:
		# If the output is not JSON, throw an error
		print("Error parsing JSON output: " + str(error))
