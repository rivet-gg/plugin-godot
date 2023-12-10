@tool extends RefCounted
## A brief description of the class's role and functionality.
##
## The description of the script, what it can do,
## and any further detail.
##
## @tutorial:            https://the/tutorial1/url.com
## @tutorial(Tutorial2): https://the/tutorial2/url.com
## @experimental
const RivetEditorSettings = preload("rivet_editor_settings.gd")
const RivetThread = preload("rivet_thread.gd")
const RivetCliOutput = preload("rivet_cli_output.gd")

var thread: RivetThread = RivetThread.new()

#region Utilities
static func find_executable(program: String) -> String:
	var os := OS.get_name()
	var output = []
	var code: int = -1
	if OS.get_name() == "Windows":
		code = OS.execute("where", [program], output, true)
	else:
		code = OS.execute("which", [program], output, true)
	
	if code == 1 or output.size() < 1:
		return ""
	return output[0].strip_escapes()

static func find_rivet():
	var editor_rivet_path = RivetEditorSettings.get_setting(RivetEditorSettings.RIVET_CLI_PATH_SETTING)
	if not editor_rivet_path or not editor_rivet_path.is_empty():
		return editor_rivet_path
	printerr("Can't find path to Rivet CLI (in editor settings)")
	
	var rivet_path = find_executable("rivet")
	if not rivet_path.is_empty():
		return rivet_path
	printerr("Can't find path to Rivet CLI (rivet exec)")
	
	var rivet_cli_path = find_executable("rivet-cli")
	if not rivet_cli_path.is_empty():
		return rivet_cli_path
	print(rivet_path, rivet_cli_path)
	printerr("Can't find path to Rivet CLI (rivet-cli exec)")
#endregion

func run(args: PackedStringArray) -> RivetCliOutput:
	var output = []
	var code = OS.execute(find_rivet(), args, output, true)
	return RivetCliOutput.new(code, output)
	
func link() -> RivetCliOutput:
	thread.execute(run.bind(["--version"]))
	var output: RivetCliOutput = await thread.wait_to_finish()
	return output
