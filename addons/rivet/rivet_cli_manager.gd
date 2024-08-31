@tool

extends Node
class_name RivetCliManager

const RIVET_CLI_VERSION = "v2.0.0-rc.4"

signal cli_installed

static func get_bin_dir():
	var home_path: String = OS.get_environment("USERPROFILE") if OS.get_name() == "Windows" else OS.get_environment("HOME")
	
	# Convert any backslashes to forward slashes
	# https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#path-separators
	home_path = home_path.replace("\\", "/")

	return home_path.path_join(".rivet").path_join(RIVET_CLI_VERSION).path_join("bin")
	
static func get_bin_name():
	if OS.has_feature("windows"):
		return "rivet-cli-x86-windows.exe"
	elif OS.has_feature("macos"):
		if OS.has_feature("arm64"):
			return "rivet-cli-aarch64-mac"
		else:
			return "rivet-cli-x86-mac"
	elif OS.has_feature("linux"):
		return "rivet-cli-x86-linux"
	else:
		RivetPluginBridge.error("Unsupported operating system or architecture")
		return null

static func get_bin_path():
	var bin_name = get_bin_name()
	if bin_name == null:
		return
	return get_bin_dir().path_join(bin_name)

func install_cli():
	if FileAccess.file_exists(get_bin_path()):
		RivetPluginBridge.log("Rivet CLI is already installed")
		# If the CLI is already installed, skip to the rest of initialization
		cli_installed.emit()
	else:
		RivetPluginBridge.log("Installing Rivet CLI")
		# Show dialog
		var dialog = AcceptDialog.new()
		dialog.title = "Downloading Rivet Toolchain"
		dialog.dialog_text = "The Rivet toolchain is being downloaded. This will take a few seconds."
		dialog.add_button("OK", true, "ok")
		add_child(dialog)
		dialog.popup_centered()

		# Create dir
		DirAccess.make_dir_recursive_absolute(get_bin_dir())

		# Download CLI
		var http_request = HTTPRequest.new()

		http_request.set_download_file(get_bin_path())
		http_request.request_completed.connect(_on_cli_download_completed)
		add_child(http_request)

		var target = get_bin_name()
		if target.is_empty():
			RivetPluginBridge.error("Failed to get CLI binary name")
			return
		
		var url = "https://releases.rivet.gg/cli/%s/%s" % [RIVET_CLI_VERSION, target]
		RivetPluginBridge.log("Downloading Rivet CLI from %s" % url)
		http_request.request(url)

func _on_cli_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	RivetPluginBridge.log("Rivet CLI download completed with result: %d, response code: %d" % [result, response_code])

	# Add response code
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		var body_string = body.get_string_from_utf8().strip_edges()
		var error_message = "Failed to download Rivet CLI. Result: %d, Response Code: %d, Body: %s" % [result, response_code, body_string]
		RivetPluginBridge.error(error_message)
		var dialog = AcceptDialog.new()
		dialog.title = "Rivet Toolchain Download Failed"
		dialog.dialog_text = error_message
		dialog.close_requested.connect(func(): dialog.queue_free())
		add_child(dialog)
		dialog.popup_centered()
		return

	# If we aren't on Windows, set the executable bit
	if OS.get_name() != "Windows":
		var command = "chmod +x " + get_bin_path()
		RivetPluginBridge.log("Setting executable bit for Rivet CLI with command: %s" % command)
		OS.execute("/bin/sh", ["-c", command])

	RivetPluginBridge.log("Rivet CLI installation completed")
	cli_installed.emit()
