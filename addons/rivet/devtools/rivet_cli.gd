extends RefCounted
## Wrapper around the Rivet CLI, allowing you to run it from GDScript in non-blocking way, and get the output.
##
## @experimental

const REQUIRED_RIVET_CLI_VERSION = "v1.3.1"

const _RivetEditorSettings = preload("rivet_editor_settings.gd")
const _RivetThread = preload("rivet_thread.gd")
const _RivetCliOutput = preload("rivet_cli_output.gd")

func check_existence() -> Error:
	var editor_rivet_path = _RivetEditorSettings.get_setting(_RivetEditorSettings.RIVET_CLI_PATH_SETTING.name)
	if not editor_rivet_path or editor_rivet_path.is_empty():
		return FAILED
	var result: _RivetCliOutput = await run_and_wait(["sidekick", "get-cli-version"])
	if result.exit_code != 0 or !("Ok" in result.output):
		return FAILED
	var cli_version = result.output["Ok"].version
	if cli_version != REQUIRED_RIVET_CLI_VERSION:
		return FAILED
	return OK

func run_and_wait(args: PackedStringArray) -> _RivetCliOutput:
	var thread: _RivetThread = _RivetThread.new(_run.bind(args))
	return await thread.wait_to_finish()

func run(args:PackedStringArray) -> _RivetThread:
	return _RivetThread.new(_run.bind(args))

func get_bin_dir() -> String:
	var home_path: String = OS.get_environment("USERPROFILE") if OS.get_name() == "Windows" else OS.get_environment("HOME")
	
	# Convert any backslashes to forward slashes
	# https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#path-separators
	home_path = home_path.replace("\\", "/")

	return home_path.path_join(".rivet").path_join(REQUIRED_RIVET_CLI_VERSION).path_join("bin")

func get_cli_path() -> String:
	var cli_path = _RivetEditorSettings.get_setting(_RivetEditorSettings.RIVET_CLI_PATH_SETTING.name)
	if cli_path and !cli_path.is_empty():
		return cli_path
	return get_bin_dir().path_join("rivet.exe" if OS.get_name() == "Windows" else "rivet")
 
func install() -> _RivetCliOutput:
	var thread: _RivetThread = _RivetThread.new(_install)
	var result = await thread.wait_to_finish()
	if result.exit_code == 0:
		_RivetEditorSettings.set_setting_value(_RivetEditorSettings.RIVET_CLI_PATH_SETTING.name, get_bin_dir() + "/rivet")
	return result


## region Internal functions

## Runs Rivet CLI with given arguments.
func _run(args: PackedStringArray) -> _RivetCliOutput:
	var output = []
	RivetPluginBridge.log(["Running Rivet CLI: ", "%s %s" % [get_cli_path(), " ".join(args)]])
	var code: int = OS.execute(get_cli_path(), args, output, true)

	return _RivetCliOutput.new(code, output)

func _install() -> _RivetCliOutput:
	var output = []
	var code: int
	var bin_dir: String = get_bin_dir()

	OS.set_environment("RIVET_CLI_VERSION", REQUIRED_RIVET_CLI_VERSION)
	OS.set_environment("BIN_DIR", bin_dir)

	# Double quotes issue: https://github.com/godotengine/godot/issues/37291#issuecomment-603821838
	if OS.get_name() == "Windows":
		var args = ["-Command",  "\"iwr https://raw.githubusercontent.com/rivet-gg/cli/$env:RIVET_CLI_VERSION/install/windows.ps1 -useb | iex; Read-Host -Prompt 'Press Enter to exit'\""]
		code = OS.execute("powershell.exe", args, output, true, true)
	else:
		#var args = ["-c", "\"'curl -fsSL https://raw.githubusercontent.com/rivet-gg/cli/${RIVET_CLI_VERSION}/install/unix.sh | sh''\""]
		var args = ["-c", "\"'curl -fsSL https://raw.githubusercontent.com/rivet-gg/cli/ac57796861d195230fa043e12c5f9fe1921f467f/install/unix.sh | sh'\""]
		code = OS.execute("/bin/sh", args, output, true, true)
	return _RivetCliOutput.new(code, output)



## endregion