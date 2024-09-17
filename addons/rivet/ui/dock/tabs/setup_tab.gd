@tool extends MarginContainer

func _ready():
	# Hide by default until requirements load
	%RequirementsContainer.visible = false

	# Steps
	%StepModules.check_setup = _moudle_check
	%StepModules.call_setup = _module_call

	%StepMultiplayer.check_setup = _multiplayer_check
	%StepMultiplayer.call_setup = _multiplayer_call

	%StepDevelop.call_setup = _develop_call

	%StepDeploy.call_setup = _deploy_call
	
	# Check requirements
	_check_requirements()

func _check_requirements():
	# If being called again, hide requirements
	%RequirementsContainer.visible = false

	# Check requirements
	var plugin = RivetPluginBridge.get_plugin()
	var requirements = await plugin.run_toolchain_task("check_system_requirements")
	
	# Prerequisites
	if requirements.errors.size() > 0:
		# Build body
		var body = "[b]System Requirements[/b]\n[indent]"
		for error in requirements.errors:
			body += "\n[b]%s[/b]\n%s" % [error.title, error.body]
			if "docs_url" in error:
				body += " [url=%s]Learn More[/url]" % error.docs_url
			body += "\n"
		body += "[/indent]"
		%Requirements.text = body

		# Show container
		%RequirementsContainer.visible = true
		%Requirements.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"bg", &"AssetLib"))
		%Requirements.add_theme_color_override(&"default_color", get_theme_color(&"warning_color", &"Editor"))
		%RequirementsIcon.modulate = get_theme_color(&"warning_color", &"Editor")
	else:
		%RequirementsContainer.visible = false

# MARK: Project Config
func _moudle_check() -> bool:
	return _backend_check() && _container_check()

func _module_call():
	if !_backend_check():
		_backend_call()
	if !_container_check():
		_container_call()

# MARK: Backend Config
const BACKEND_FILES = {
	"rivet.json": "rivet.json",
	"rivet.dev.json": "rivet.dev.json",
}

func _backend_check() -> bool:
	return _check_files_exist(BACKEND_FILES)

func _backend_call():
	_copy_files(BACKEND_FILES)

# MARK: Container
const CONTAINER_FILES = {
	"Dockerfile": "Dockerfile",
	"dockerignore": ".dockerignore",
}

func _container_check() -> bool:
	return _check_files_exist(CONTAINER_FILES)

func _container_call():
	_copy_files(CONTAINER_FILES)

# MARK: Setup Multiplayer
var MULTIPLAYER_FILES_TEXTURES = {
	"template_2d/assets/crate.png": "assets/crate.png",
	"template_2d/assets/player.png": "assets/player.png",
	"template_2d/player.gd": "player.gd",
}

var MULTIPLAYER_FILES_SCENES = {
	"template_2d/crate.tscn": "crate.tscn",
	"template_2d/player.tscn": "player.tscn",
}

var MULTIPLAYER_FILES_SCRIPTS = {
	"template_2d/main.gd": "main.gd",
	"template_2d/main.tscn": "main.tscn",
}

func _multiplayer_check() -> bool:
	var all_files = {}
	all_files.merge(MULTIPLAYER_FILES_TEXTURES)
	all_files.merge(MULTIPLAYER_FILES_SCENES)
	all_files.merge(MULTIPLAYER_FILES_SCRIPTS)
	return _check_files_exist(all_files)

func _multiplayer_call():
	# Copy scenes
	_copy_files(MULTIPLAYER_FILES_TEXTURES)
	_copy_files(MULTIPLAYER_FILES_SCENES)

	# Update scenes
	_add_sprite_2d("res://player.tscn", "assets/player.tres")
	_add_sprite_2d("res://crate.tscn", "assets/crate.tres")

	# Copy scripts after scenes are loaded
	_copy_files(MULTIPLAYER_FILES_SCRIPTS)

	# Update main scene
	var default_scene_path = "res://main.tscn"
	ProjectSettings.set_setting("application/run/main_scene", default_scene_path)
	var err = ProjectSettings.save()
	if err != OK:
		RivetPluginBridge.error("Failed to save project settings: " + str(err))

	# Open scene
	EditorInterface.open_scene_from_path(default_scene_path)

# MARK: Develop
func _develop_call():
	owner.change_tab(1)

# MARK: Deploy
func _deploy_call():
	owner.change_tab(2)

# MARK: Next Steps
func _config_modules_call():
	owner.change_tab(3)

# MARK: Helper
func _get_plugin_path() -> String:
	var script_path = get_script().get_path().get_base_dir().get_base_dir().get_base_dir().get_base_dir()
	return script_path

# Check that all files exist. If we will overwrite one, the old one will be moved to `.old`.
func _check_files_exist(file_map: Dictionary, source_dir: String = "resources") -> bool:
	var full_source_dir = _get_plugin_path().path_join(source_dir)
	
	for source_file in file_map:
		var dest_path = file_map[source_file]
		if !FileAccess.file_exists(dest_path):
			return false
	return true

func _copy_files(file_map: Dictionary, source_dir: String = "resources") -> void:
	var full_source_dir = _get_plugin_path().path_join(source_dir)
	
	for source_file in file_map:
		var source_path = full_source_dir.path_join(source_file)
		var dest_path = file_map[source_file]
		
		# Ensure the destination directory exists
		var dest_dir = dest_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(dest_dir):
			var dir_err = DirAccess.make_dir_recursive_absolute(dest_dir)
			if dir_err != OK:
				RivetPluginBridge.error("Failed to create destination directory: " + dest_dir)
				continue
			else:
				RivetPluginBridge.log("Created destination directory: " + dest_dir)

		# Copy the file
		var err = DirAccess.copy_absolute(source_path, dest_path)
		if err != OK:
			RivetPluginBridge.error("Failed to copy " + source_file + " to " + dest_path + ": " + str(err))
		else:
			RivetPluginBridge.log("Successfully copied " + source_file + " to " + dest_path)
			EditorInterface.get_resource_filesystem().update_file(dest_path)
			
			# Import special file types
			if dest_path.get_extension().to_lower() == "png":
				_import_png(dest_path)


	# Scan for updates
	# EditorInterface.get_resource_filesystem().scan()
	# await EditorInterface.get_resource_filesystem().sources_changed

func _add_sprite_2d(scene_path: String, texture_path: String):
	RivetPluginBridge.log('Adding sprite to scene: %s %s' % [scene_path, texture_path])
	var scene = load(scene_path)
	if scene:
		var root = scene.instantiate()
		
		# Create a new Sprite2D node
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		
		# Load and set the texture
		var texture = load(texture_path)
		if texture:
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			RivetPluginBridge.error("Failed to load texture: " + texture_path)
			return
		
		# Add the new Sprite2D to the root
		root.add_child(sprite)
		sprite.owner = root
		
		var packed_scene = PackedScene.new()
		var pack_result = packed_scene.pack(root)
		if pack_result == OK:
			var save_result = ResourceSaver.save(packed_scene, scene_path)
			if save_result == OK:
				RivetPluginBridge.log("Successfully added Sprite2D to scene: " + scene_path)
			else:
				RivetPluginBridge.error("Failed to save updated scene: " + scene_path)
		else:
			RivetPluginBridge.error("Failed to pack scene: " + scene_path)
	else:
		RivetPluginBridge.error("Failed to load scene: " + scene_path)

func _import_png(path: String):
	var image = Image.new()
	var err = image.load(path)
	if err != OK:
		RivetPluginBridge.error("Failed to load PNG: " + path + ", error: " + str(err))
		return err

	# Create the ImageTexture from the image
	var texture = ImageTexture.create_from_image(image)

	# Save as a StreamTexture2D
	err = ResourceSaver.save(texture, path.get_basename() + ".tres")
	if err != OK:
		RivetPluginBridge.error("Failed to save texture: " + path + ", error: " + str(err))
	else:
		RivetPluginBridge.log("Successfully imported and saved texture: " + path)

	# Update the import metadata
	EditorInterface.get_resource_filesystem().update_file(path.get_basename() + ".tres")
