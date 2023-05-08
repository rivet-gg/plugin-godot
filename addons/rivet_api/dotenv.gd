extends Object
class_name DotEnv

static func config():
	var path = "res://.env"
	
	# Check if .env exists
	if !FileAccess.file_exists(path):
		RivetHelper.rivet_print(".env does not exist")
		return
		
	# Read .env file
	var file = FileAccess.open(path, FileAccess.READ)
	while !file.eof_reached():
		var line = file.get_line()
		
		# Ignore comments
		if line.begins_with("#"):
			continue
		
		# Split line
		var split = line.split("=", true, 2)
		if split.size() != 2:
			continue
		var key = split[0]
		var value = split[1]
		
		# Trim quotes from value
		if value.begins_with("\"") and value.ends_with("\""):
			value = value.substr(1, value.length() - 2)
		
		# Set env
		OS.set_environment(split[0], split[1])
