var exit_code: ExitCode
var output: Array
var formatted_output: Array = []

enum ExitCode {
	SUCCESS = 0
	# TODO: fill with the rest of the exit codes
}

func _init(exit_code: int, output: Array) -> void:
	self.exit_code = exit_code
	self.output = output
	

	self.formatted_output = self.output.map(
		func (line: String): 
			# TODO(compat): test this on windows as it may have different EOFs
			return line.split("\n")
	).reduce(
		func (accum, line): 
			accum.append_array(line) 
			return accum
	,[])
