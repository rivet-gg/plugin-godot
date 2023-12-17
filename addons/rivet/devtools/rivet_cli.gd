extends RefCounted
## Wrapper aroudn the Rivet CLI, allowing you to run it from GDScript in non-blocking way, and get the output.
##
## @experimental

const REQUIRED_RIVET_CLI_VERSION = "0.1.0"

const _RivetEditorSettings = preload("rivet_editor_settings.gd")
const _RivetThread = preload("rivet_thread.gd")
const _RivetCliOutput = preload("rivet_cli_output.gd")

#region Utilities
## Finds executable in PATH using `where` on Windows and `which` on Linux and macOS.
static func find_executable(program: String) -> String:
	var os: String = OS.get_name()
	var output = []
	var code: int = -1
	if OS.get_name() == "Windows":
		code = OS.execute("where", [program], output, true)
	else:
		code = OS.execute("which", [program], output, true)
	
	if code == 1 or output.size() < 1:
		return ""
	return output[0].strip_escapes()

## Finds Rivet CLI executable in PATH or in editor settings.
static func find_rivet():
	#var editor_rivet_path = _RivetEditorSettings.get_setting(_RivetEditorSettings.RIVET_CLI_PATH_SETTING)
	#if not editor_rivet_path or not editor_rivet_path.is_empty():
	#	return editor_rivet_path
	printerr("Can't find path to Rivet CLI (in editor settings)")
	
	#var rivet_path = find_executable("rivet")
	#if not rivet_path.is_empty():
	#	return rivet_path
	#printerr("Can't find path to Rivet CLI (rivet exec)")
	
	var rivet_cli_path = find_executable("rivet-cli")
	if not rivet_cli_path.is_empty():
		return rivet_cli_path
	printerr("Can't find path to Rivet CLI (rivet-cli exec)")
#endregion

## Runs Rivet CLI with given arguments.
func run(args: PackedStringArray) -> _RivetCliOutput:
	var output = []
	var code = OS.execute(find_rivet(), args, output, true)
	print("Running Rivet CLI: ", "rivet %s" % " ".join(args))

	return _RivetCliOutput.new(code, output)

## Links your game with Rivet Cloud, using `rivet link` command.
func run_command(args: PackedStringArray) -> _RivetCliOutput:
	var thread: _RivetThread = _RivetThread.new(run.bind(args))
	
	return await thread.wait_to_finish()

func _install() -> _RivetCliOutput:
	var output = []
	var code
	print(OS.get_name())
	if OS.get_name() == "Windows":
		code = OS.execute("powershell.exe", ["-Commandi",  "$env:RIVET_CLI_VERSION='v0.3.0'; iwr https://raw.githubusercontent.com/rivet-gg/cli/$env:RIVET_CLI_VERSION/install/windows.ps1 -useb | iex"], output, true, true)
	elif OS.get_name() == "macOS":
		var args = ['"/bin/bash -e curl -fsSL https://raw.githubusercontent.com/rivet-gg/cli/main/install/unix.sh | sh"']
		OS.create_process("/System/Applications/Utilities/Terminal.app", args)
	else:
		code = OS.execute('/bin/bash', ['-c', "\"curl -fsSL https://raw.githubusercontent.com/rivet-gg/cli/main/install/unix.sh | sh\""], output, true, true)
	return _RivetCliOutput.new(code, output)
 
func install() -> _RivetCliOutput:
	var thread: _RivetThread = _RivetThread.new(_install)
	return await thread.wait_to_finish() 