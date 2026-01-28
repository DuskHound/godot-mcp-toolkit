#!/usr/bin/env -S godot --headless --script
extends SceneTree

## Godot MCP Operations v2.0
## GDScript operations for MCP server integration
##
## Supports:
## - Scene operations (create, add_node, edit_node, remove_node, save)
## - Resource operations (load_sprite, export_mesh_library)
## - UID operations (get_uid, resave_resources)
## - Script operations (read_script, list_scripts)
## - Project operations (get_project_settings, get_scene_tree)

var debug_mode := false

func _init() -> void:
	var args := OS.get_cmdline_args()

	# Check for debug flag
	debug_mode = "--debug-godot" in args or "--debug" in args

	# Find the script argument and determine the positions of operation and params
	var script_index := args.find("--script")
	if script_index == -1:
		log_error("Could not find --script argument")
		quit(1)
		return

	# The operation should be 2 positions after the script path
	var operation_index := script_index + 2
	var params_index := script_index + 3

	if args.size() <= params_index:
		log_error("Usage: godot --headless --script godot_operations.gd <operation> <json_params>")
		log_error("Not enough command-line arguments provided.")
		print_available_operations()
		quit(1)
		return

	log_debug("All arguments: " + str(args))

	var operation := args[operation_index]
	var params_json := args[params_index]

	log_info("Operation: " + operation)
	log_debug("Params JSON: " + params_json)

	# Parse JSON
	var json := JSON.new()
	var error := json.parse(params_json)
	var params: Variant = null

	if error == OK:
		params = json.get_data()
	else:
		log_error("Failed to parse JSON parameters: " + params_json)
		log_error("JSON Error: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		quit(1)
		return

	if not params:
		log_error("Failed to parse JSON parameters: " + params_json)
		quit(1)
		return

	log_info("Executing operation: " + operation)

	# Execute operation
	match operation:
		# Scene operations
		"create_scene":
			create_scene(params)
		"add_node":
			add_node(params)
		"edit_node":
			edit_node(params)
		"remove_node":
			remove_node(params)
		"load_sprite":
			load_sprite(params)
		"save_scene":
			save_scene(params)

		# Resource operations
		"export_mesh_library":
			export_mesh_library(params)

		# UID operations
		"get_uid":
			get_uid(params)
		"resave_resources":
			resave_resources(params)

		# Script operations
		"read_script":
			read_script(params)
		"list_scripts":
			list_scripts(params)

		# Project operations
		"get_project_settings":
			get_project_settings(params)
		"get_scene_tree":
			get_scene_tree(params)
		"list_scenes":
			list_scenes(params)
		"validate_project":
			validate_project(params)

		_:
			log_error("Unknown operation: " + operation)
			print_available_operations()
			quit(1)
			return

	quit()

func print_available_operations() -> void:
	log_info("Available operations:")
	log_info("  Scene: create_scene, add_node, edit_node, remove_node, load_sprite, save_scene")
	log_info("  Resource: export_mesh_library")
	log_info("  UID: get_uid, resave_resources")
	log_info("  Script: read_script, list_scripts")
	log_info("  Project: get_project_settings, get_scene_tree, list_scenes, validate_project")


# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

func log_debug(message: String) -> void:
	if debug_mode:
		print("[DEBUG] " + message)

func log_info(message: String) -> void:
	print("[INFO] " + message)

func log_error(message: String) -> void:
	printerr("[ERROR] " + message)

func log_success(message: String) -> void:
	print("[SUCCESS] " + message)


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func get_script_by_name(name_of_class: String) -> Script:
	log_debug("Attempting to get script for class: " + name_of_class)

	# Try to load it directly if it's a resource path
	if ResourceLoader.exists(name_of_class, "Script"):
		log_debug("Resource exists, loading directly: " + name_of_class)
		var script := load(name_of_class) as Script
		if script:
			log_debug("Successfully loaded script from path")
			return script
		else:
			log_error("Failed to load script from path: " + name_of_class)
	else:
		log_debug("Resource not found, checking global class registry")

	# Search for it in the global class registry
	var global_classes := ProjectSettings.get_global_class_list()
	log_debug("Searching through " + str(global_classes.size()) + " global classes")

	for global_class in global_classes:
		var found_name_of_class: String = global_class["class"]
		var found_path: String = global_class["path"]

		if found_name_of_class == name_of_class:
			log_debug("Found matching class in registry: " + found_name_of_class + " at path: " + found_path)
			var script := load(found_path) as Script
			if script:
				log_debug("Successfully loaded script from registry")
				return script
			else:
				log_error("Failed to load script from registry path: " + found_path)
				break

	log_error("Could not find script for class: " + name_of_class)
	return null


func instantiate_class(name_of_class: String) -> Node:
	if name_of_class.is_empty():
		log_error("Cannot instantiate class: name is empty")
		return null

	var result: Node = null
	log_debug("Attempting to instantiate class: " + name_of_class)

	# Check if it's a built-in class
	if ClassDB.class_exists(name_of_class):
		log_debug("Class exists in ClassDB, using ClassDB.instantiate()")
		if ClassDB.can_instantiate(name_of_class):
			result = ClassDB.instantiate(name_of_class) as Node
			if result == null:
				log_error("ClassDB.instantiate() returned null for class: " + name_of_class)
		else:
			log_error("Class exists but cannot be instantiated: " + name_of_class)
	else:
		# Try to get the script
		log_debug("Class not found in ClassDB, trying to get script")
		var script := get_script_by_name(name_of_class)
		if script is GDScript:
			log_debug("Found GDScript, creating instance")
			result = script.new() as Node
		else:
			log_error("Failed to get script for class: " + name_of_class)
			return null

	if result == null:
		log_error("Failed to instantiate class: " + name_of_class)
	else:
		log_debug("Successfully instantiated class: " + name_of_class + " of type: " + result.get_class())

	return result


func normalize_path(path: String) -> String:
	if not path.begins_with("res://"):
		return "res://" + path
	return path


func ensure_directory(dir_path: String) -> bool:
	var absolute_path := ProjectSettings.globalize_path(dir_path)

	if DirAccess.dir_exists_absolute(absolute_path):
		return true

	var relative_path := dir_path.substr(6) if dir_path.begins_with("res://") else dir_path

	var dir := DirAccess.open("res://")
	if dir == null:
		log_error("Failed to open res:// directory")
		return false

	var make_dir_error := dir.make_dir_recursive(relative_path)
	if make_dir_error != OK:
		log_error("Failed to create directory: " + dir_path + " (error: " + str(make_dir_error) + ")")
		return false

	return true


# ============================================================================
# SCENE OPERATIONS
# ============================================================================

func create_scene(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var root_node_type: String = params.get("root_node_type", "Node2D")

	log_info("Creating scene: " + scene_path + " with root type: " + root_node_type)

	# Ensure directory exists
	var scene_dir := scene_path.get_base_dir()
	if not ensure_directory(scene_dir):
		quit(1)
		return

	# Create the root node
	var scene_root := instantiate_class(root_node_type)
	if not scene_root:
		log_error("Failed to instantiate node of type: " + root_node_type)
		quit(1)
		return

	scene_root.name = "root"

	# Pack and save the scene
	var packed_scene := PackedScene.new()
	var result := packed_scene.pack(scene_root)

	if result != OK:
		log_error("Failed to pack scene: " + str(result))
		quit(1)
		return

	var save_error := ResourceSaver.save(packed_scene, scene_path)
	if save_error != OK:
		log_error("Failed to save scene: " + str(save_error))
		quit(1)
		return

	# Verify
	if FileAccess.file_exists(scene_path):
		log_success("Scene created successfully: " + scene_path)
	else:
		log_error("Scene file not found after save: " + scene_path)
		quit(1)


func add_node(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var parent_path: String = params.get("parent_node_path", "root")

	log_info("Adding node to scene: " + scene_path)

	var absolute_scene_path := ProjectSettings.globalize_path(scene_path)
	if not FileAccess.file_exists(absolute_scene_path):
		log_error("Scene file does not exist: " + absolute_scene_path)
		quit(1)
		return

	var scene := load(scene_path)
	if not scene:
		log_error("Failed to load scene: " + scene_path)
		quit(1)
		return

	var scene_root := scene.instantiate()

	# Find parent node
	var parent := scene_root
	if parent_path != "root":
		parent = scene_root.get_node(parent_path.replace("root/", ""))
		if not parent:
			log_error("Parent node not found: " + parent_path)
			quit(1)
			return

	# Create new node
	var new_node := instantiate_class(params.node_type)
	if not new_node:
		log_error("Failed to instantiate node of type: " + params.node_type)
		quit(1)
		return

	new_node.name = params.node_name

	# Set properties if provided
	if params.has("properties"):
		for property in params.properties:
			new_node.set(property, params.properties[property])

	# Add to parent and set owner
	parent.add_child(new_node)
	new_node.owner = scene_root

	# Save the scene
	var packed_scene := PackedScene.new()
	var result := packed_scene.pack(scene_root)

	if result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Node '" + params.node_name + "' added successfully")
		else:
			log_error("Failed to save scene: " + str(save_error))
	else:
		log_error("Failed to pack scene: " + str(result))


func edit_node(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var node_path: String = params.node_path

	log_info("Editing node in scene: " + scene_path)

	var absolute_scene_path := ProjectSettings.globalize_path(scene_path)
	if not FileAccess.file_exists(absolute_scene_path):
		log_error("Scene file does not exist: " + absolute_scene_path)
		quit(1)
		return

	var scene := load(scene_path)
	if not scene:
		log_error("Failed to load scene: " + scene_path)
		quit(1)
		return

	var scene_root := scene.instantiate()

	# Find target node
	var target_node := scene_root
	if node_path != "root":
		target_node = scene_root.get_node(node_path.replace("root/", ""))
		if not target_node:
			log_error("Target node not found: " + node_path)
			quit(1)
			return

	# Update properties
	if params.has("properties"):
		for property in params.properties:
			target_node.set(property, params.properties[property])

	# Save the scene
	var packed_scene := PackedScene.new()
	var result := packed_scene.pack(scene_root)

	if result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Node '" + node_path + "' updated successfully")
		else:
			log_error("Failed to save scene: " + str(save_error))
			quit(1)
	else:
		log_error("Failed to pack scene: " + str(result))
		quit(1)


func remove_node(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var node_path: String = params.node_path

	log_info("Removing node from scene: " + scene_path)

	if node_path == "root":
		log_error("Cannot remove the root node")
		quit(1)
		return

	var absolute_scene_path := ProjectSettings.globalize_path(scene_path)
	if not FileAccess.file_exists(absolute_scene_path):
		log_error("Scene file does not exist: " + absolute_scene_path)
		quit(1)
		return

	var scene := load(scene_path)
	if not scene:
		log_error("Failed to load scene: " + scene_path)
		quit(1)
		return

	var scene_root := scene.instantiate()

	var target_node := scene_root.get_node(node_path.replace("root/", ""))
	if not target_node:
		log_error("Target node not found: " + node_path)
		quit(1)
		return

	var parent_node := target_node.get_parent()
	if not parent_node:
		log_error("Target node has no parent: " + node_path)
		quit(1)
		return

	parent_node.remove_child(target_node)
	target_node.queue_free()

	# Save the scene
	var packed_scene := PackedScene.new()
	var result := packed_scene.pack(scene_root)

	if result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Node '" + node_path + "' removed successfully")
		else:
			log_error("Failed to save scene: " + str(save_error))
			quit(1)
	else:
		log_error("Failed to pack scene: " + str(result))
		quit(1)


func load_sprite(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var texture_path := normalize_path(params.texture_path)

	log_info("Loading sprite into scene: " + scene_path)

	if not FileAccess.file_exists(scene_path):
		log_error("Scene file does not exist: " + scene_path)
		quit(1)
		return

	var scene := load(scene_path)
	if not scene:
		log_error("Failed to load scene: " + scene_path)
		quit(1)
		return

	var scene_root := scene.instantiate()

	# Find the sprite node
	var node_path: String = params.node_path
	if node_path.begins_with("root/"):
		node_path = node_path.substr(5)

	var sprite_node: Node = scene_root if node_path.is_empty() else scene_root.get_node(node_path)

	if not sprite_node:
		log_error("Node not found: " + params.node_path)
		quit(1)
		return

	# Check if compatible
	if not (sprite_node is Sprite2D or sprite_node is Sprite3D or sprite_node is TextureRect):
		log_error("Node is not a sprite-compatible type: " + sprite_node.get_class())
		quit(1)
		return

	# Load texture
	var texture := load(texture_path)
	if not texture:
		log_error("Failed to load texture: " + texture_path)
		quit(1)
		return

	# Set texture
	sprite_node.texture = texture

	# Save the scene
	var packed_scene := PackedScene.new()
	var result := packed_scene.pack(scene_root)

	if result == OK:
		var error := ResourceSaver.save(packed_scene, scene_path)
		if error == OK:
			log_success("Sprite loaded with texture: " + texture_path)
		else:
			log_error("Failed to save scene: " + str(error))
	else:
		log_error("Failed to pack scene: " + str(result))


func save_scene(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var save_path: String = normalize_path(params.get("new_path", params.scene_path))

	log_info("Saving scene: " + scene_path + " -> " + save_path)

	if not FileAccess.file_exists(scene_path):
		log_error("Scene file does not exist: " + scene_path)
		quit(1)
		return

	var scene := load(scene_path)
	if not scene:
		log_error("Failed to load scene: " + scene_path)
		quit(1)
		return

	var scene_root := scene.instantiate()

	# Ensure save directory exists
	if params.has("new_path"):
		var save_dir := save_path.get_base_dir()
		if not ensure_directory(save_dir):
			quit(1)
			return

	# Pack and save
	var packed_scene := PackedScene.new()
	var result := packed_scene.pack(scene_root)

	if result == OK:
		var error := ResourceSaver.save(packed_scene, save_path)
		if error == OK:
			log_success("Scene saved to: " + save_path)
		else:
			log_error("Failed to save scene: " + str(error))
	else:
		log_error("Failed to pack scene: " + str(result))


# ============================================================================
# RESOURCE OPERATIONS
# ============================================================================

func export_mesh_library(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var output_path := normalize_path(params.output_path)

	log_info("Exporting MeshLibrary from: " + scene_path)

	if not FileAccess.file_exists(scene_path):
		log_error("Scene file does not exist: " + scene_path)
		quit(1)
		return

	var scene := load(scene_path)
	if not scene:
		log_error("Failed to load scene: " + scene_path)
		quit(1)
		return

	var scene_root := scene.instantiate()
	var mesh_library := MeshLibrary.new()

	var mesh_item_names: Array = params.get("mesh_item_names", [])
	var use_specific_items := mesh_item_names.size() > 0

	var item_id := 0

	for child in scene_root.get_children():
		if use_specific_items and not (child.name in mesh_item_names):
			continue

		var mesh_instance: MeshInstance3D = null
		if child is MeshInstance3D:
			mesh_instance = child
		else:
			for descendant in child.get_children():
				if descendant is MeshInstance3D:
					mesh_instance = descendant
					break

		if mesh_instance and mesh_instance.mesh:
			mesh_library.create_item(item_id)
			mesh_library.set_item_name(item_id, child.name)
			mesh_library.set_item_mesh(item_id, mesh_instance.mesh)

			# Add collision shape if available
			for collision_child in child.get_children():
				if collision_child is CollisionShape3D and collision_child.shape:
					mesh_library.set_item_shapes(item_id, [collision_child.shape])
					break

			item_id += 1

	if item_id > 0:
		var save_dir := output_path.get_base_dir()
		if not ensure_directory(save_dir):
			quit(1)
			return

		var error := ResourceSaver.save(mesh_library, output_path)
		if error == OK:
			log_success("MeshLibrary exported with " + str(item_id) + " items to: " + output_path)
		else:
			log_error("Failed to save MeshLibrary: " + str(error))
	else:
		log_error("No valid meshes found in the scene")


# ============================================================================
# UID OPERATIONS
# ============================================================================

func get_uid(params: Dictionary) -> void:
	var file_path := normalize_path(params.file_path)

	log_info("Getting UID for: " + file_path)

	var absolute_path := ProjectSettings.globalize_path(file_path)

	if not FileAccess.file_exists(file_path):
		log_error("File does not exist: " + file_path)
		quit(1)
		return

	var uid_path := file_path + ".uid"
	var f := FileAccess.open(uid_path, FileAccess.READ)

	if f:
		var uid_content := f.get_as_text()
		f.close()

		var result := {
			"file": file_path,
			"absolutePath": absolute_path,
			"uid": uid_content.strip_edges(),
			"exists": true
		}
		print(JSON.stringify(result))
	else:
		var result := {
			"file": file_path,
			"absolutePath": absolute_path,
			"exists": false,
			"message": "UID file does not exist. Use resave_resources to generate UIDs."
		}
		print(JSON.stringify(result))


func resave_resources(params: Dictionary) -> void:
	log_info("Resaving all resources to update UID references...")

	var project_path: String = params.get("project_path", "res://")
	if not project_path.begins_with("res://"):
		project_path = "res://" + project_path
	if not project_path.ends_with("/"):
		project_path += "/"

	var scenes := find_files(project_path, ".tscn")
	var success_count := 0
	var error_count := 0

	for scene_path in scenes:
		var scene := load(scene_path)
		if scene:
			var error := ResourceSaver.save(scene, scene_path)
			if error == OK:
				success_count += 1
			else:
				error_count += 1
		else:
			error_count += 1

	var scripts := find_files(project_path, ".gd")
	scripts.append_array(find_files(project_path, ".gdshader"))

	var missing_uids := 0
	var generated_uids := 0

	for script_path in scripts:
		var uid_path := script_path + ".uid"
		var f := FileAccess.open(uid_path, FileAccess.READ)
		if not f:
			missing_uids += 1
			var res := load(script_path)
			if res:
				var error := ResourceSaver.save(res, script_path)
				if error == OK:
					generated_uids += 1

	log_info("Resave complete:")
	log_info("  Scenes: " + str(success_count) + " saved, " + str(error_count) + " errors")
	log_info("  Missing UIDs: " + str(missing_uids) + ", Generated: " + str(generated_uids))
	log_success("Resave operation complete")


func find_files(path: String, extension: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(path)

	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()

		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				files.append_array(find_files(path + file_name + "/", extension))
			elif file_name.ends_with(extension):
				files.append(path + file_name)

			file_name = dir.get_next()

	return files


# ============================================================================
# SCRIPT OPERATIONS
# ============================================================================

func read_script(params: Dictionary) -> void:
	var script_path := normalize_path(params.script_path)

	log_info("Reading script: " + script_path)

	if not FileAccess.file_exists(script_path):
		log_error("Script file does not exist: " + script_path)
		quit(1)
		return

	var f := FileAccess.open(script_path, FileAccess.READ)
	if f:
		var content := f.get_as_text()
		f.close()

		var result := {
			"path": script_path,
			"content": content,
			"lines": content.split("\n").size()
		}
		print(JSON.stringify(result))
	else:
		log_error("Failed to read script: " + script_path)
		quit(1)


func list_scripts(params: Dictionary) -> void:
	var search_path: String = normalize_path(params.get("path", "res://scripts"))

	log_info("Listing scripts in: " + search_path)

	var scripts := find_files(search_path, ".gd")

	var result := {
		"path": search_path,
		"count": scripts.size(),
		"scripts": scripts
	}
	print(JSON.stringify(result))


# ============================================================================
# PROJECT OPERATIONS
# ============================================================================

func get_project_settings(params: Dictionary) -> void:
	log_info("Getting project settings")

	var settings := {}

	# Get common project settings
	settings["project_name"] = ProjectSettings.get_setting("application/config/name", "Unknown")
	settings["main_scene"] = ProjectSettings.get_setting("application/run/main_scene", "")
	settings["features"] = ProjectSettings.get_setting("application/config/features", [])

	# Get autoloads
	var autoloads := []
	var autoload_section := ProjectSettings.get_global_class_list()

	# Parse project.godot for autoloads
	var project_file := FileAccess.open("res://project.godot", FileAccess.READ)
	if project_file:
		var content := project_file.get_as_text()
		project_file.close()

		var in_autoload := false
		for line in content.split("\n"):
			if line.begins_with("[autoload]"):
				in_autoload = true
				continue
			elif line.begins_with("["):
				in_autoload = false
				continue

			if in_autoload and "=" in line:
				var parts := line.split("=")
				if parts.size() >= 2:
					autoloads.append({
						"name": parts[0].strip_edges(),
						"path": parts[1].strip_edges().replace("\"", "")
					})

	settings["autoloads"] = autoloads

	var result := {
		"settings": settings
	}
	print(JSON.stringify(result))


func get_scene_tree(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)

	log_info("Getting scene tree: " + scene_path)

	if not FileAccess.file_exists(scene_path):
		log_error("Scene file does not exist: " + scene_path)
		quit(1)
		return

	var scene := load(scene_path)
	if not scene:
		log_error("Failed to load scene: " + scene_path)
		quit(1)
		return

	var scene_root := scene.instantiate()

	var tree := _build_node_tree(scene_root, "")

	var result := {
		"scene": scene_path,
		"tree": tree
	}
	print(JSON.stringify(result))


func _build_node_tree(node: Node, path: String) -> Dictionary:
	var node_info := {
		"name": node.name,
		"type": node.get_class(),
		"path": path + "/" + node.name if not path.is_empty() else node.name,
		"children": []
	}

	# Add script info if present
	if node.get_script():
		var script: Script = node.get_script()
		node_info["script"] = script.resource_path

	# Recursively add children
	for child in node.get_children():
		node_info["children"].append(_build_node_tree(child, node_info["path"]))

	return node_info


func list_scenes(params: Dictionary) -> void:
	var search_path: String = normalize_path(params.get("path", "res://"))

	log_info("Listing scenes in: " + search_path)

	var scenes := find_files(search_path, ".tscn")

	var result := {
		"path": search_path,
		"count": scenes.size(),
		"scenes": scenes
	}
	print(JSON.stringify(result))


func validate_project(params: Dictionary) -> void:
	log_info("Validating project...")

	var issues := []
	var warnings := []

	# Check project.godot exists
	if not FileAccess.file_exists("res://project.godot"):
		issues.append("project.godot not found")

	# Check main scene
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene.is_empty():
		warnings.append("No main scene configured")
	elif not FileAccess.file_exists(main_scene):
		issues.append("Main scene not found: " + main_scene)

	# Check autoloads
	var project_file := FileAccess.open("res://project.godot", FileAccess.READ)
	if project_file:
		var content := project_file.get_as_text()
		project_file.close()

		var in_autoload := false
		for line in content.split("\n"):
			if line.begins_with("[autoload]"):
				in_autoload = true
				continue
			elif line.begins_with("["):
				in_autoload = false
				continue

			if in_autoload and "=" in line:
				var parts := line.split("=")
				if parts.size() >= 2:
					var path := parts[1].strip_edges().replace("\"", "").replace("*", "")
					if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
						issues.append("Autoload not found: " + parts[0].strip_edges() + " -> " + path)

	# Count resources
	var scripts := find_files("res://", ".gd")
	var scenes := find_files("res://", ".tscn")

	var result := {
		"valid": issues.size() == 0,
		"issues": issues,
		"warnings": warnings,
		"stats": {
			"scripts": scripts.size(),
			"scenes": scenes.size()
		}
	}
	print(JSON.stringify(result))

	if issues.size() > 0:
		log_error("Project validation failed with " + str(issues.size()) + " issues")
	else:
		log_success("Project validation passed")
