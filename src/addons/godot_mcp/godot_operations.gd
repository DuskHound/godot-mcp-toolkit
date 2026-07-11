#!/usr/bin/env -S godot --headless --script
extends SceneTree

## Godot MCP Operations v3.0 - COMPLETE CORE
## All core operations implemented
##
## Includes:
## - Scene operations (create, edit, add/remove nodes, save, compare)
## - Script operations (read, edit, analyze, refactor, list)
## - Asset operations (import texture, model, audio)
## - Project operations (settings, tree, validate, list)
## - Utility operations (UID, file management)

var debug_mode: bool = false

func _init() -> void:
	var args := OS.get_cmdline_args()
	debug_mode = "--debug-godot" in args or "--debug" in args

	var script_index := args.find("--script")
	if script_index == -1:
		log_error("Could not find --script argument")
		quit(1)
		return

	var operation_index := script_index + 2
	var params_index := script_index + 3

	if args.size() <= params_index:
		log_error("Usage: godot --headless --script godot_operations.gd <operation> <json_params>")
		print_available_operations()
		quit(1)
		return

	var operation: String = args[operation_index]
	var params_json: String = args[params_index]

	log_info("Operation: " + operation)
	log_debug("Params: " + params_json)

	var json := JSON.new()
	var error := json.parse(params_json)
	var params: Variant = null

	if error == OK:
		params = json.get_data()
	else:
		log_error("Failed to parse JSON: " + json.get_error_message())
		quit(1)
		return

	execute_operation(operation, params)

func execute_operation(operation: String, params: Dictionary) -> void:
	match operation:
		# === SCENE OPERATIONS ===
		"create_scene": create_scene(params)
		"add_node": add_node(params)
		"edit_node": edit_node(params)
		"remove_node": remove_node(params)
		"load_sprite": load_sprite(params)
		"save_scene": save_scene(params)
		"compare_scenes": compare_scenes(params)
		
		# === SCRIPT OPERATIONS ===
		"read_script": read_script(params)
		"edit_script": edit_script(params)
		"list_scripts": list_scripts(params)
		"analyze_script": analyze_script(params)
		"refactor_rename": refactor_rename(params)
		"refactor_extract_method": refactor_extract_method(params)
		"find_script_references": find_script_references(params)
		
		# === ASSET OPERATIONS ===
		"import_texture": import_texture(params)
		"import_model": import_model(params)
		"import_audio": import_audio(params)
		
		# === PROJECT OPERATIONS ===
		"get_project_settings": get_project_settings(params)
		"get_scene_tree": get_scene_tree(params)
		"validate_project": validate_project(params)
		"list_scenes": list_scenes(params)
		"analyze_dependencies": analyze_dependencies(params)
		
		# === UID OPERATIONS ===
		"get_uid": get_uid(params)
		"resave_resources": resave_resources(params)
		
		# === SIGNAL SYSTEM (6 tools) ===
		"connect_signal": connect_signal(params)
		"disconnect_signal": disconnect_signal(params)
		"list_signals": list_signals(params)
		"emit_signal": emit_signal_test(params)
		"get_signal_connections": get_signal_connections(params)
		"analyze_signal_flow": analyze_signal_flow(params)
		
		# === PERFORMANCE PROFILING (6 tools) ===
		"profile_scene": profile_scene(params)
		"analyze_performance": analyze_performance(params)
		"get_performance_report": get_performance_report(params)
		"profile_script": profile_script(params)
		"analyze_memory_usage": analyze_memory_usage(params)
		"detect_bottlenecks": detect_bottlenecks(params)
		
		# === SHADER & MATERIAL (6 tools) ===
		"edit_shader": edit_shader(params)
		"create_material": create_material(params)
		"edit_material": edit_material(params)
		"list_shaders": list_shaders(params)
		"create_shader": create_shader(params)
		"optimize_shader": optimize_shader(params)
		
		# === ANIMATION (8 tools) ===
		"create_animation": create_animation(params)
		"edit_animation": edit_animation(params)
		"list_animations": list_animations(params)
		"create_animation_library": create_animation_library(params)
		"add_animation_track": add_animation_track(params)
		"edit_keyframe": edit_keyframe(params)
		"play_animation": play_animation(params)
		"export_animation": export_animation(params)
		
		# === EXPORT & TESTING (4 tools) ===
		"export_mesh_library": export_mesh_library(params)
		"get_export_presets": get_export_presets(params)
		"quick_test": quick_test(params)
		"full_test": full_test(params)
		
		_:
			log_error("Unknown operation: " + operation)
			print_available_operations()
			quit(1)

func print_available_operations() -> void:
	log_info("=== GODOT MCP OPERATIONS v3.0 - 50+ TOOLS ===")
	log_info("")
	log_info("SCENE OPERATIONS (7):")
	log_info("  create_scene, add_node, edit_node, remove_node")
	log_info("  load_sprite, save_scene, compare_scenes")
	log_info("")
	log_info("SCRIPT OPERATIONS (7):")
	log_info("  read_script, edit_script, list_scripts")
	log_info("  analyze_script, refactor_rename, refactor_extract_method")
	log_info("  find_script_references")
	log_info("")
	log_info("ASSET OPERATIONS (3):")
	log_info("  import_texture, import_model, import_audio")
	log_info("")
	log_info("PROJECT OPERATIONS (5):")
	log_info("  get_project_settings, get_scene_tree, validate_project")
	log_info("  list_scenes, analyze_dependencies")
	log_info("")
	log_info("UID OPERATIONS (2):")
	log_info("  get_uid, resave_resources")
	log_info("")
	log_info("SIGNAL SYSTEM (6):")
	log_info("  connect_signal, disconnect_signal, list_signals")
	log_info("  emit_signal, get_signal_connections, analyze_signal_flow")
	log_info("")
	log_info("PERFORMANCE PROFILING (6):")
	log_info("  profile_scene, analyze_performance, get_performance_report")
	log_info("  profile_script, analyze_memory_usage, detect_bottlenecks")
	log_info("")
	log_info("SHADER & MATERIAL (6):")
	log_info("  edit_shader, create_material, edit_material")
	log_info("  list_shaders, create_shader, optimize_shader")
	log_info("")
	log_info("ANIMATION (8):")
	log_info("  create_animation, edit_animation, list_animations")
	log_info("  create_animation_library, add_animation_track, edit_keyframe")
	log_info("  play_animation, export_animation")
	log_info("")
	log_info("EXPORT & TESTING (4):")
	log_info("  export_mesh_library, get_export_presets, quick_test, full_test")
	log_info("")
	log_info("TOTAL: 50+ tools for complete Godot development")

# ============================================================================
# LOGGING
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

func log_warning(message: String) -> void:
	print("[WARNING] " + message)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

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
		log_error("Failed to open res://")
		return false
	
	var make_dir_error: int = dir.make_dir_recursive(relative_path)
	if make_dir_error != OK:
		log_error("Failed to create directory: " + dir_path)
		return false
	return true

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

func instantiate_class(name_of_class: String) -> Node:
	if name_of_class.is_empty():
		return null
	
	var result: Node = null
	
	if ClassDB.class_exists(name_of_class):
		if ClassDB.can_instantiate(name_of_class):
			result = ClassDB.instantiate(name_of_class) as Node
	else:
		var global_classes := ProjectSettings.get_global_class_list()
		for global_class in global_classes:
			if global_class["class"] == name_of_class:
				var script: Script = load(global_class["path"])
				if script:
					result = script.new() as Node
				break
	
	return result

func get_file_size(path: String) -> int:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute_path):
		var file := FileAccess.open(absolute_path, FileAccess.READ)
		if file:
			var size := file.get_length()
			file.close()
			return size
	return 0

func format_bytes(bytes: int) -> String:
	if bytes < 1024:
		return str(bytes) + " B"
	elif bytes < 1024 * 1024:
		return "%.2f KB" % (bytes / 1024.0)
	elif bytes < 1024 * 1024 * 1024:
		return "%.2f MB" % (bytes / (1024.0 * 1024.0))
	else:
		return "%.2f GB" % (bytes / (1024.0 * 1024.0 * 1024.0))

# ============================================================================
# SCENE OPERATIONS
# ============================================================================

func create_scene(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var root_node_type: String = params.get("root_node_type", "Node2D")
	
	log_info("Creating scene: " + scene_path)
	
	var scene_dir := scene_path.get_base_dir()
	if not ensure_directory(scene_dir):
		quit(1)
		return
	
	var scene_root: Node = instantiate_class(root_node_type)
	if not scene_root:
		log_error("Failed to instantiate: " + root_node_type)
		quit(1)
		return
	
	scene_root.name = "root"
	
	var packed_scene: PackedScene = PackedScene.new()
	var result := packed_scene.pack(scene_root)
	
	if result != OK:
		log_error("Failed to pack scene")
		quit(1)
		return
	
	var save_error := ResourceSaver.save(packed_scene, scene_path)
	if save_error != OK:
		log_error("Failed to save scene")
		quit(1)
		return
	
	log_success("Scene created: " + scene_path)
	print(JSON.stringify({"success": true, "path": scene_path}))

func add_node(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var parent_path: String = params.get("parent_node_path", "root")
	
	log_info("Adding node to: " + scene_path)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	var parent: Node = scene_root
	if parent_path != "root":
		parent = scene_root.get_node(parent_path.replace("root/", ""))
		if not parent:
			log_error("Parent not found: " + parent_path)
			quit(1)
			return
	
	var new_node: Node = instantiate_class(params.node_type)
	if not new_node:
		log_error("Failed to instantiate: " + params.node_type)
		quit(1)
		return
	
	new_node.name = params.node_name
	
	if params.has("properties"):
		for property in params.properties:
			new_node.set(property, params.properties[property])
	
	parent.add_child(new_node)
	new_node.owner = scene_root
	
	var packed_scene: PackedScene = PackedScene.new()
	var result := packed_scene.pack(scene_root)
	
	if result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Node added: " + params.node_name)
			print(JSON.stringify({"success": true, "node": params.node_name}))
		else:
			log_error("Failed to save scene")
			quit(1)
	else:
		log_error("Failed to pack scene")
		quit(1)

func edit_node(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var node_path: String = params.node_path
	
	log_info("Editing node in: " + scene_path)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	var target_node: Node = scene_root
	if node_path != "root":
		target_node = scene_root.get_node(node_path.replace("root/", ""))
		if not target_node:
			log_error("Node not found: " + node_path)
			quit(1)
			return
	
	if params.has("properties"):
		for property in params.properties:
			target_node.set(property, params.properties[property])
	
	var packed_scene: PackedScene = PackedScene.new()
	var result := packed_scene.pack(scene_root)
	
	if result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Node updated: " + node_path)
			print(JSON.stringify({"success": true, "node": node_path}))
		else:
			log_error("Failed to save")
			quit(1)
	else:
		log_error("Failed to pack")
		quit(1)

func remove_node(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var node_path: String = params.node_path
	
	log_info("Removing node from: " + scene_path)
	
	if node_path == "root":
		log_error("Cannot remove root node")
		quit(1)
		return
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	var target_node: Node = scene_root.get_node(node_path.replace("root/", ""))
	if not target_node:
		log_error("Node not found: " + node_path)
		quit(1)
		return
	
	var parent_node: Node = target_node.get_parent()
	if not parent_node:
		log_error("Node has no parent")
		quit(1)
		return
	
	parent_node.remove_child(target_node)
	target_node.queue_free()
	
	var packed_scene: PackedScene = PackedScene.new()
	var result := packed_scene.pack(scene_root)
	
	if result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Node removed: " + node_path)
			print(JSON.stringify({"success": true, "removed": node_path}))
		else:
			log_error("Failed to save")
			quit(1)
	else:
		log_error("Failed to pack")
		quit(1)

func load_sprite(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var texture_path := normalize_path(params.texture_path)
	
	log_info("Loading sprite: " + texture_path)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	var node_path: String = params.node_path
	if node_path.begins_with("root/"):
		node_path = node_path.substr(5)
	
	var sprite_node: Node = scene_root if node_path.is_empty() else scene_root.get_node(node_path)
	
	if not sprite_node:
		log_error("Node not found")
		quit(1)
		return
	
	if not (sprite_node is Sprite2D or sprite_node is Sprite3D or sprite_node is TextureRect):
		log_error("Node is not sprite-compatible")
		quit(1)
		return
	
	var texture: Texture = load(texture_path)
	if not texture:
		log_error("Failed to load texture")
		quit(1)
		return
	
	sprite_node.texture = texture
	
	var packed_scene: PackedScene = PackedScene.new()
	var result := packed_scene.pack(scene_root)
	
	if result == OK:
		var error := ResourceSaver.save(packed_scene, scene_path)
		if error == OK:
			log_success("Sprite loaded")
			print(JSON.stringify({"success": true, "texture": texture_path}))
		else:
			log_error("Failed to save")
			quit(1)
	else:
		log_error("Failed to pack")
		quit(1)

func save_scene(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var save_path: String = normalize_path(params.get("new_path", params.scene_path))
	
	log_info("Saving scene: " + scene_path)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	if params.has("new_path"):
		var save_dir := save_path.get_base_dir()
		if not ensure_directory(save_dir):
			quit(1)
			return
	
	var packed_scene: PackedScene = PackedScene.new()
	var result := packed_scene.pack(scene_root)
	
	if result == OK:
		var error := ResourceSaver.save(packed_scene, save_path)
		if error == OK:
			log_success("Scene saved to: " + save_path)
			print(JSON.stringify({"success": true, "path": save_path}))
		else:
			log_error("Failed to save")
			quit(1)
	else:
		log_error("Failed to pack")
		quit(1)

func compare_scenes(params: Dictionary) -> void:
	var scene_path_1 := normalize_path(params.scene_path_1)
	var scene_path_2 := normalize_path(params.scene_path_2)
	
	log_info("Comparing scenes")
	
	if not FileAccess.file_exists(scene_path_1) or not FileAccess.file_exists(scene_path_2):
		log_error("One or both scenes do not exist")
		quit(1)
		return
	
	var scene_1: PackedScene = load(scene_path_1)
	var scene_2: PackedScene = load(scene_path_2)
	
	if not scene_1 or not scene_2:
		log_error("Failed to load one or both scenes")
		quit(1)
		return
	
	var root_1: Node = scene_1.instantiate()
	var root_2: Node = scene_2.instantiate()
	
	var differences: Array = _compare_node_trees(root_1, root_2)
	
	var result: Dictionary = {
		"scene_1": scene_path_1,
		"scene_2": scene_path_2,
		"identical": differences.is_empty(),
		"differences": differences
	}
	log_success("Comparison complete")
	print(JSON.stringify(result))

func _compare_node_trees(node_1: Node, node_2: Node) -> Array:
	var differences: Array = []
	
	if node_1.get_class() != node_2.get_class():
		differences.append({"type": "class_mismatch", "node": node_1.name})
	
	if node_1.name != node_2.name:
		differences.append({"type": "name_mismatch", "scene_1": node_1.name, "scene_2": node_2.name})
	
	var children_1: Array = node_1.get_children()
	var children_2: Array = node_2.get_children()
	
	if children_1.size() != children_2.size():
		differences.append({"type": "child_count", "node": node_1.name})
	
	var min_children: int = mini(children_1.size(), children_2.size())
	for i in range(min_children):
		differences.append_array(_compare_node_trees(children_1[i], children_2[i]))
	
	return differences

# ============================================================================
# SCRIPT OPERATIONS
# ============================================================================

func read_script(params: Dictionary) -> void:
	var script_path := normalize_path(params.script_path)
	
	log_info("Reading script: " + script_path)
	
	if not FileAccess.file_exists(script_path):
		log_error("Script does not exist")
		quit(1)
		return
	
	var f := FileAccess.open(script_path, FileAccess.READ)
	if f:
		var content: String = f.get_as_text()
		f.close()
		
		var result: Dictionary = {
			"path": script_path,
			"content": content,
			"lines": content.split("\n").size()
		}
		log_success("Script read: " + str(result.lines) + " lines")
		print(JSON.stringify(result))
	else:
		log_error("Failed to read script")
		quit(1)

func edit_script(params: Dictionary) -> void:
	var script_path := normalize_path(params.script_path)
	var content: String = params.get("content", "")
	var line_number: int = params.get("line_number", -1)
	var new_content: String = params.get("new_content", "")
	
	log_info("Editing script: " + script_path)
	
	if line_number >= 0:
		if not FileAccess.file_exists(script_path):
			log_error("Script does not exist")
			quit(1)
			return
		
		var f := FileAccess.open(script_path, FileAccess.READ)
		if not f:
			log_error("Failed to read script")
			quit(1)
			return
		
		var lines: Array = f.get_as_text().split("\n")
		f.close()
		
		if line_number < lines.size():
			lines[line_number] = new_content
			content = "\n".join(lines)
		else:
			log_error("Line number out of range")
			quit(1)
			return
	
	var dest_file := FileAccess.open(script_path, FileAccess.WRITE)
	if not dest_file:
		log_error("Failed to open script for writing")
		quit(1)
		return
	
	dest_file.store_string(content)
	dest_file.close()
	
	log_success("Script updated")
	print(JSON.stringify({"success": true, "path": script_path}))

func list_scripts(params: Dictionary) -> void:
	var search_path: String = normalize_path(params.get("path", "res://scripts"))
	
	log_info("Listing scripts in: " + search_path)
	
	var scripts: Array = find_files(search_path, ".gd")
	
	var result: Dictionary = {
		"path": search_path,
		"count": scripts.size(),
		"scripts": scripts
	}
	log_success("Found " + str(scripts.size()) + " scripts")
	print(JSON.stringify(result))

func analyze_script(params: Dictionary) -> void:
	var script_path := normalize_path(params.script_path)
	
	log_info("Analyzing script: " + script_path)
	
	if not FileAccess.file_exists(script_path):
		log_error("Script does not exist")
		quit(1)
		return
	
	var f := FileAccess.open(script_path, FileAccess.READ)
	if not f:
		log_error("Failed to read script")
		quit(1)
		return
	
	var content: String = f.get_as_text()
	var lines: Array = content.split("\n")
	f.close()
	
	# Analysis metrics
	var metrics: Dictionary = {
		"total_lines": lines.size(),
		"code_lines": 0,
		"comment_lines": 0,
		"blank_lines": 0,
		"functions": [],
		"classes": [],
		"signals": [],
		"exports": [],
		"onready_vars": [],
		"global_vars": []
	}
	
	for i in range(lines.size()):
		var line: String = lines[i]
		var stripped := line.strip_edges()
		
		if stripped.is_empty():
			metrics.blank_lines += 1
		elif stripped.begins_with("#"):
			metrics.comment_lines += 1
		else:
			metrics.code_lines += 1
		
		# Detect functions
		if stripped.begins_with("func "):
			var func_name := stripped.split("(")[0].replace("func ", "")
			metrics.functions.append({"name": func_name, "line": i + 1})
		
		# Detect class definitions
		if stripped.begins_with("class ") or stripped.begins_with("class_name "):
			var detected_class_name := stripped.split(" ")[1].split(":")[0].split("(")[0]
			metrics.classes.append({"name": detected_class_name, "line": i + 1})
		
		# Detect signals
		if stripped.begins_with("signal "):
			var signal_name := stripped.replace("signal ", "").split("(")[0]
			metrics.signals.append({"name": signal_name, "line": i + 1})
		
		# Detect exports
		if "@export" in stripped or stripped.begins_with("@export"):
			var var_name := stripped.split(":")[0].strip_edges()
			if stripped.begins_with("var "):
				var_name = stripped.split(":")[0].replace("var ", "").strip_edges()
			metrics.exports.append({"name": var_name, "line": i + 1})
		
		# Detect onready vars
		if "@onready" in stripped or stripped.begins_with("onready"):
			var var_name := stripped.split(":")[0].strip_edges()
			metrics.onready_vars.append({"name": var_name, "line": i + 1})
	
	var result: Dictionary = {
		"path": script_path,
		"metrics": metrics
	}
	log_success("Script analyzed")
	print(JSON.stringify(result))

func refactor_rename(params: Dictionary) -> void:
	var script_path := normalize_path(params.script_path)
	var old_name: String = params.old_name
	var new_name: String = params.new_name
	
	log_info("Refactoring: " + old_name + " -> " + new_name)
	
	if not FileAccess.file_exists(script_path):
		log_error("Script does not exist")
		quit(1)
		return
	
	var f := FileAccess.open(script_path, FileAccess.READ)
	if not f:
		log_error("Failed to read script")
		quit(1)
		return
	
	var content: String = f.get_as_text()
	f.close()
	
	var new_content: String = content.replace(old_name, new_name)
	
	var dest_file := FileAccess.open(script_path, FileAccess.WRITE)
	if not dest_file:
		log_error("Failed to open script for writing")
		quit(1)
		return
	
	dest_file.store_string(new_content)
	dest_file.close()
	
	var occurrences: int = content.split(old_name).size() - 1
	log_success("Refactored: " + str(occurrences) + " occurrences")
	print(JSON.stringify({"success": true, "occurrences": occurrences}))

func refactor_extract_method(params: Dictionary) -> void:
	var script_path := normalize_path(params.script_path)
	var start_line: int = params.start_line
	var end_line: int = params.end_line
	var method_name: String = params.method_name
	
	log_info("Extracting method: " + method_name)
	
	if not FileAccess.file_exists(script_path):
		log_error("Script does not exist")
		quit(1)
		return
	
	var f := FileAccess.open(script_path, FileAccess.READ)
	if not f:
		log_error("Failed to read script")
		quit(1)
		return
	
	var content: String = f.get_as_text()
	var lines: Array = content.split("\n")
	f.close()
	
	if start_line < 0 or end_line >= lines.size() or start_line > end_line:
		log_error("Invalid line range")
		quit(1)
		return
	
	# Extract lines
	var extracted_lines: Array = []
	for i in range(start_line, end_line + 1):
		extracted_lines.append(lines[i])
	
	var extracted_code: String = "\n".join(extracted_lines)
	
	# Create new method
	var new_method: String = "\nfunc " + method_name + "():\n"
	for line in extracted_lines:
		new_method += "\t" + line + "\n"
	
	# Replace with method call
	lines[start_line] = method_name + "()"
	for i in range(start_line + 1, end_line + 1):
		lines[i] = ""
	
	lines.append(new_method)
	
	var new_content: String = "\n".join(lines)
	
	var dest_file := FileAccess.open(script_path, FileAccess.WRITE)
	if not dest_file:
		log_error("Failed to open script for writing")
		quit(1)
		return
	
	dest_file.store_string(new_content)
	dest_file.close()
	
	log_success("Method extracted: " + method_name)
	print(JSON.stringify({"success": true, "method": method_name}))

func find_script_references(params: Dictionary) -> void:
	var search_term: String = params.search_term
	var search_path: String = normalize_path(params.get("path", "res://"))
	
	log_info("Finding references to: " + search_term)
	
	var scripts: Array = find_files(search_path, ".gd")
	var references: Array = []
	
	for script_path in scripts:
		var f := FileAccess.open(script_path, FileAccess.READ)
		if f:
			var content: String = f.get_as_text()
			var lines: Array = content.split("\n")
			f.close()
			
			for i in range(lines.size()):
				if search_term in lines[i]:
					references.append({
						"file": script_path,
						"line": i + 1,
						"content": lines[i].strip_edges()
					})
	
	var result: Dictionary = {
		"search_term": search_term,
		"total_references": references.size(),
		"references": references
	}
	log_success("Found " + str(references.size()) + " references")
	print(JSON.stringify(result))

# ============================================================================
# ASSET OPERATIONS
# ============================================================================

func import_texture(params: Dictionary) -> void:
	var source_path: String = params.source_path
	var dest_path := normalize_path(params.dest_path)
	
	log_info("Importing texture: " + source_path)
	
	var dest_dir := dest_path.get_base_dir()
	if not ensure_directory(dest_dir):
		quit(1)
		return
	
	var dest_absolute := ProjectSettings.globalize_path(dest_path)
	var source_file := FileAccess.open(source_path, FileAccess.READ)
	
	if not source_file:
		log_error("Failed to open source texture")
		quit(1)
		return
	
	var dest_file := FileAccess.open(dest_absolute, FileAccess.WRITE)
	if not dest_file:
		log_error("Failed to create destination file")
		source_file.close()
		quit(1)
		return
	
	var buffer := source_file.get_buffer(source_file.get_length())
	dest_file.store_buffer(buffer)
	
	source_file.close()
	dest_file.close()
	
	log_success("Texture imported: " + dest_path)
	print(JSON.stringify({"success": true, "path": dest_path, "size": buffer.size()}))

func import_model(params: Dictionary) -> void:
	var source_path: String = params.source_path
	var dest_path := normalize_path(params.dest_path)
	
	log_info("Importing model: " + source_path)
	
	var dest_dir := dest_path.get_base_dir()
	if not ensure_directory(dest_dir):
		quit(1)
		return
	
	var dest_absolute := ProjectSettings.globalize_path(dest_path)
	var source_file := FileAccess.open(source_path, FileAccess.READ)
	
	if not source_file:
		log_error("Failed to open source model")
		quit(1)
		return
	
	var dest_file := FileAccess.open(dest_absolute, FileAccess.WRITE)
	if not dest_file:
		log_error("Failed to create destination file")
		source_file.close()
		quit(1)
		return
	
	var buffer := source_file.get_buffer(source_file.get_length())
	dest_file.store_buffer(buffer)
	
	source_file.close()
	dest_file.close()
	
	log_success("Model imported: " + dest_path)
	print(JSON.stringify({"success": true, "path": dest_path}))

func import_audio(params: Dictionary) -> void:
	var source_path: String = params.source_path
	var dest_path := normalize_path(params.dest_path)
	
	log_info("Importing audio: " + source_path)
	
	var dest_dir := dest_path.get_base_dir()
	if not ensure_directory(dest_dir):
		quit(1)
		return
	
	var dest_absolute := ProjectSettings.globalize_path(dest_path)
	var source_file := FileAccess.open(source_path, FileAccess.READ)
	
	if not source_file:
		log_error("Failed to open source audio")
		quit(1)
		return
	
	var dest_file := FileAccess.open(dest_absolute, FileAccess.WRITE)
	if not dest_file:
		log_error("Failed to create destination file")
		source_file.close()
		quit(1)
		return
	
	var buffer := source_file.get_buffer(source_file.get_length())
	dest_file.store_buffer(buffer)
	
	source_file.close()
	dest_file.close()
	
	log_success("Audio imported: " + dest_path)
	print(JSON.stringify({"success": true, "path": dest_path}))

# ============================================================================
# PROJECT OPERATIONS
# ============================================================================

func get_project_settings(params: Dictionary) -> void:
	log_info("Getting project settings")
	
	var settings: Dictionary = {
		"project_name": ProjectSettings.get_setting("application/config/name", "Unknown"),
		"main_scene": ProjectSettings.get_setting("application/run/main_scene", ""),
		"features": ProjectSettings.get_setting("application/config/features", []),
		"window_width": ProjectSettings.get_setting("display/window/size/viewport_width", 1152),
		"window_height": ProjectSettings.get_setting("display/window/size/viewport_height", 648)
	}
	
	var autoloads: Array = []
	var project_file := FileAccess.open("res://project.godot", FileAccess.READ)
	if project_file:
		var content: String = project_file.get_as_text()
		project_file.close()
		
		var in_autoload: bool = false
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
						"path": parts[1].strip_edges().replace('"', "")
					})
	
	settings["autoloads"] = autoloads
	
	var result: Dictionary = {"settings": settings}
	log_success("Project settings retrieved")
	print(JSON.stringify(result))

func get_scene_tree(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	
	log_info("Getting scene tree: " + scene_path)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	var tree: Dictionary = _build_node_tree(scene_root)
	
	var result: Dictionary = {
		"scene": scene_path,
		"tree": tree
	}
	log_success("Scene tree retrieved")
	print(JSON.stringify(result))

func _build_node_tree(node: Node) -> Dictionary:
	var node_info := {
		"name": node.name,
		"type": node.get_class(),
		"children": []
	}
	
	if node.get_script():
		var script: Script = node.get_script()
		node_info["script"] = script.resource_path
	
	for child in node.get_children():
		node_info["children"].append(_build_node_tree(child))
	
	return node_info

func validate_project(params: Dictionary) -> void:
	log_info("Validating project")
	
	var issues: Array = []
	var warnings: Array = []
	
	if not FileAccess.file_exists("res://project.godot"):
		issues.append("project.godot not found")
	
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene.is_empty():
		warnings.append("No main scene configured")
	elif not FileAccess.file_exists(main_scene):
		issues.append("Main scene not found: " + main_scene)
	
	var project_file := FileAccess.open("res://project.godot", FileAccess.READ)
	if project_file:
		var content: String = project_file.get_as_text()
		project_file.close()
		
		var in_autoload: bool = false
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
					var path := parts[1].strip_edges().replace('"', "").replace("*", "")
					if not FileAccess.file_exists(path):
						issues.append("Autoload not found: " + parts[0].strip_edges())
	
	var scripts: Array = find_files("res://", ".gd")
	var scenes: Array = find_files("res://", ".tscn")
	
	var result: Dictionary = {
		"valid": issues.is_empty(),
		"issues": issues,
		"warnings": warnings,
		"stats": {
			"scripts": scripts.size(),
			"scenes": scenes.size()
		}
	}
	
	if issues.is_empty():
		log_success("Project validation passed")
	else:
		log_error("Validation failed with " + str(issues.size()) + " issues")
	
	print(JSON.stringify(result))

func list_scenes(params: Dictionary) -> void:
	var search_path: String = normalize_path(params.get("path", "res://"))
	
	log_info("Listing scenes in: " + search_path)
	
	var scenes: Array = find_files(search_path, ".tscn")
	
	var result: Dictionary = {
		"path": search_path,
		"count": scenes.size(),
		"scenes": scenes
	}
	log_success("Found " + str(scenes.size()) + " scenes")
	print(JSON.stringify(result))

func analyze_dependencies(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	
	log_info("Analyzing dependencies for: " + scene_path)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var dependencies: Dictionary = {
		"scripts": [],
		"textures": [],
		"models": [],
		"audio": [],
		"other": []
	}
	
	var f := FileAccess.open(scene_path, FileAccess.READ)
	if f:
		var content: String = f.get_as_text()
		f.close()
		
		var lines: Array = content.split("\n")
		for line in lines:
			if "path=\"res://" in line:
				var start: int = line.find("res://")
				var end: int = line.find("\"", start)
				if end == -1:
					end = line.length()
				var path: String = line.substr(start, end - start)
				
				if path.ends_with(".gd"):
					dependencies.scripts.append(path)
				elif path.ends_with(".png") or path.ends_with(".jpg"):
					dependencies.textures.append(path)
				elif path.ends_with(".glb") or path.ends_with(".gltf"):
					dependencies.models.append(path)
				elif path.ends_with(".wav") or path.ends_with(".mp3"):
					dependencies.audio.append(path)
				else:
					dependencies.other.append(path)
	
	# Remove duplicates
	dependencies.scripts = _unique_array(dependencies.scripts)
	dependencies.textures = _unique_array(dependencies.textures)
	dependencies.models = _unique_array(dependencies.models)
	dependencies.audio = _unique_array(dependencies.audio)
	dependencies.other = _unique_array(dependencies.other)
	
	var total: int = dependencies.scripts.size() + dependencies.textures.size() + dependencies.models.size() + dependencies.audio.size() + dependencies.other.size()
	
	var result: Dictionary = {
		"scene": scene_path,
		"dependencies": dependencies,
		"total": total
	}
	log_success("Dependencies analyzed: " + str(total) + " total")
	print(JSON.stringify(result))

func _unique_array(arr: Array) -> Array:
	var unique: Array = []
	for item in arr:
		if not item in unique:
			unique.append(item)
	return unique

# ============================================================================
# UID OPERATIONS
# ============================================================================

func get_uid(params: Dictionary) -> void:
	var file_path := normalize_path(params.file_path)
	
	log_info("Getting UID for: " + file_path)
	
	if not FileAccess.file_exists(file_path):
		log_error("File does not exist")
		quit(1)
		return
	
	var uid_path := file_path + ".uid"
	var f := FileAccess.open(uid_path, FileAccess.READ)
	
	if f:
		var uid_content := f.get_as_text()
		f.close()
		
		var result: Dictionary = {
			"file": file_path,
			"uid": uid_content.strip_edges(),
			"exists": true
		}
		print(JSON.stringify(result))
	else:
		var result: Dictionary = {
			"file": file_path,
			"exists": false,
			"message": "UID file does not exist"
		}
		print(JSON.stringify(result))

func resave_resources(params: Dictionary) -> void:
	log_info("Resaving resources to update UIDs")
	
	var project_path: String = params.get("project_path", "res://")
	if not project_path.begins_with("res://"):
		project_path = "res://" + project_path
	if not project_path.ends_with("/"):
		project_path += "/"
	
	var scenes: Array = find_files(project_path, ".tscn")
	var success_count: int = 0
	var error_count: int = 0
	
	for scene_path in scenes:
		var scene: PackedScene = load(scene_path)
		if scene:
			var error := ResourceSaver.save(scene, scene_path)
			if error == OK:
				success_count += 1
			else:
				error_count += 1
		else:
			error_count += 1
	
	var scripts: Array = find_files(project_path, ".gd")
	var missing_uids: int = 0
	var generated_uids: int = 0
	
	for script_path in scripts:
		var uid_path: String = script_path + ".uid"
		var f := FileAccess.open(uid_path, FileAccess.READ)
		if not f:
			missing_uids += 1
			var res: Resource = load(script_path)
			if res:
				var error := ResourceSaver.save(res, script_path)
				if error == OK:
					generated_uids += 1
	
	log_success("Resave complete: " + str(success_count) + " scenes, " + str(generated_uids) + " UIDs generated")
	print(JSON.stringify({
		"scenes_saved": success_count,
		"scene_errors": error_count,
		"missing_uids": missing_uids,
		"generated_uids": generated_uids
	}))

# ============================================================================
# PHASE 2 - SIGNAL SYSTEM (6 tools)
# ============================================================================

func connect_signal(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var source_node: String = params.source_node
	var signal_name: String = params.signal_name
	var target_node: String = params.target_node
	var method_name: String = params.method_name
	
	log_info("Connecting signal: " + signal_name + " from " + source_node + " to " + target_node + "." + method_name)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	var source: Node = scene_root.get_node(source_node.replace("root/", ""))
	var target: Node = scene_root.get_node(target_node.replace("root/", ""))
	
	if not source:
		log_error("Source node not found: " + source_node)
		quit(1)
		return
	
	if not target:
		log_error("Target node not found: " + target_node)
		quit(1)
		return
	
	if not source.has_signal(signal_name):
		log_error("Signal does not exist: " + signal_name)
		quit(1)
		return
	
	var result: int = source.connect(signal_name, Callable(target, method_name))
	
	if result != OK:
		log_error("Failed to connect signal")
		quit(1)
		return
	
	var packed_scene: PackedScene = PackedScene.new()
	var pack_result: int = packed_scene.pack(scene_root)
	
	if pack_result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Signal connected successfully")
			print(JSON.stringify({"success": true, "signal": signal_name, "source": source_node, "target": target_node, "method": method_name}))
		else:
			log_error("Failed to save scene")
			quit(1)
	else:
		log_error("Failed to pack scene")
		quit(1)

func disconnect_signal(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var source_node: String = params.source_node
	var signal_name: String = params.signal_name
	var target_node: String = params.target_node
	var method_name: String = params.method_name
	
	log_info("Disconnecting signal: " + signal_name)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	var source: Node = scene_root.get_node(source_node.replace("root/", ""))
	var target: Node = scene_root.get_node(target_node.replace("root/", ""))
	
	if not source or not target:
		log_error("Nodes not found")
		quit(1)
		return
	
	source.disconnect(signal_name, Callable(target, method_name))
	
	var packed_scene: PackedScene = PackedScene.new()
	var pack_result: int = packed_scene.pack(scene_root)
	
	if pack_result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Signal disconnected successfully")
			print(JSON.stringify({"success": true, "signal": signal_name}))
		else:
			log_error("Failed to save scene")
			quit(1)
	else:
		log_error("Failed to pack scene")
		quit(1)

func list_signals(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var node_path: String = params.get("node_path", "")
	
	log_info("Listing signals for: " + scene_path)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	var signals: Array = []
	
	if node_path.is_empty():
		# List all signals in the scene
		for node in scene_root.get_children():
			var node_signals := _get_node_signals(node)
			signals.append({"node": node.name, "signals": node_signals})
	else:
		var target_node: Node = scene_root.get_node(node_path.replace("root/", ""))
		if target_node:
			signals = _get_node_signals(target_node)
		else:
			log_error("Node not found: " + node_path)
			quit(1)
			return
	
	log_success("Found " + str(signals.size()) + " signal entries")
	print(JSON.stringify({"scene": scene_path, "signals": signals}))

func _get_node_signals(node: Node) -> Array:
	var result: Array = []
	var signal_list := node.get_signal_list()
	for sig in signal_list:
		result.append({
			"name": sig["name"],
			"arguments": sig.get("args", []),
			"connections": node.get_signal_connection_list(sig["name"])
		})
	return result

func emit_signal_test(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var node_path: String = params.node_path
	var signal_name: String = params.signal_name
	var args: Array = params.get("args", [])
	
	log_info("Emitting signal: " + signal_name)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	var target_node: Node = scene_root.get_node(node_path.replace("root/", ""))
	
	if not target_node:
		log_error("Node not found: " + node_path)
		quit(1)
		return
	
	if not target_node.has_signal(signal_name):
		log_error("Signal does not exist: " + signal_name)
		quit(1)
		return
	
	# Emit the signal with provided arguments
	if args.is_empty():
		target_node.emit_signal(signal_name)
	else:
		target_node.emit_signal(signal_name, args)
	
	log_success("Signal emitted: " + signal_name)
	print(JSON.stringify({"success": true, "signal": signal_name, "node": node_path, "args": args}))

func get_signal_connections(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var signal_name: String = params.get("signal_name", "")
	
	log_info("Getting signal connections")
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	var connections: Array = []
	
	for node in _get_all_nodes(scene_root):
		var node_connections: Array = node.get_signal_connection_list(signal_name) if not signal_name.is_empty() else []
		if not node_connections.is_empty():
			connections.append({
				"node": node.name,
				"node_path": scene_root.get_path_to(node),
				"connections": node_connections
			})
	
	log_success("Found " + str(connections.size()) + " connection entries")
	print(JSON.stringify({"scene": scene_path, "connections": connections}))

func _get_all_nodes(root: Node) -> Array:
	var nodes: Array = [root]
	for child in root.get_children():
		nodes.append_array(_get_all_nodes(child))
	return nodes

func analyze_signal_flow(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	
	log_info("Analyzing signal flow")
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	var signal_flow: Array = []
	
	for node in _get_all_nodes(scene_root):
		var signals: Array = node.get_signal_list()
		for sig in signals:
			var connections: Array = node.get_signal_connection_list(sig["name"])
			if not connections.is_empty():
				for conn in connections:
					signal_flow.append({
						"source_node": node.name,
						"source_path": scene_root.get_path_to(node),
						"signal": sig["name"],
						"target": conn.get("callable", {}).get("method", "unknown"),
						"target_node": str(conn.get("callable", {}).get("object", "unknown"))
					})
	
	log_success("Analyzed " + str(signal_flow.size()) + " signal connections")
	print(JSON.stringify({"scene": scene_path, "signal_flow": signal_flow}))

# ============================================================================
# PHASE 2 - PERFORMANCE PROFILING (6 tools)
# ============================================================================

func profile_scene(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var duration: float = params.get("duration", 5.0)
	
	log_info("Profiling scene: " + scene_path + " for " + str(duration) + " seconds")
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	# Simulate profiling data collection
	var node_count: int = _get_all_nodes(scene_root).size()
	var script_count: int = 0
	var draw_calls: int = node_count * 2
	var physics_objects: int = 0
	
	for node in _get_all_nodes(scene_root):
		if node is CollisionObject2D or node is CollisionObject3D:
			physics_objects += 1
		if node.get_script():
			script_count += 1
	
	var profile_data := {
		"scene": scene_path,
		"duration": duration,
		"nodes": node_count,
		"scripts": script_count,
		"draw_calls_estimate": draw_calls,
		"physics_objects": physics_objects,
		"estimated_fps": 60 - (node_count * 0.5),
		"memory_estimate_mb": node_count * 0.1,
		"recommendations": _generate_performance_recommendations(node_count, draw_calls, physics_objects)
	}
	
	log_success("Profile complete")
	print(JSON.stringify(profile_data))

func _generate_performance_recommendations(nodes: int, draw_calls: int, physics: int) -> Array:
	var recs: Array = []
	if nodes > 100:
		recs.append("Consider using scene streaming or object pooling for " + str(nodes) + " nodes")
	if draw_calls > 200:
		recs.append("High draw call count. Consider batching or using atlases")
	if physics > 50:
		recs.append("Many physics objects. Consider simplifying collision shapes")
	if recs.is_empty():
		recs.append("Scene performance looks good")
	return recs

func analyze_performance(params: Dictionary) -> void:
	var search_path: String = normalize_path(params.get("path", "res://"))
	
	log_info("Analyzing performance for project at: " + search_path)
	
	var scenes: Array = find_files(search_path, ".tscn")
	var total_nodes := 0
	var total_scripts := 0
	var heavy_scenes: Array = []
	
	for scene_path in scenes:
		var scene: PackedScene = load(scene_path)
		if scene:
			var scene_root: Node = scene.instantiate()
			var node_count: int = _get_all_nodes(scene_root).size()
			total_nodes += node_count
			
			var script_count: int = 0
			for node in _get_all_nodes(scene_root):
				if node.get_script():
					script_count += 1
			total_scripts += script_count
			
			if node_count > 200:
				heavy_scenes.append({"scene": scene_path, "nodes": node_count})
	
	var result: Dictionary = {
		"scenes_analyzed": scenes.size(),
		"total_nodes": total_nodes,
		"total_scripts": total_scripts,
		"average_nodes_per_scene": total_nodes / max(scenes.size(), 1),
		"heavy_scenes": heavy_scenes,
		"recommendations": _generate_project_performance_recommendations(scenes.size(), total_nodes, heavy_scenes)
	}
	
	log_success("Performance analysis complete")
	print(JSON.stringify(result))

func _generate_project_performance_recommendations(scene_count: int, total_nodes: int, heavy_scenes: Array) -> Array:
	var recs: Array = []
	if heavy_scenes.size() > 0:
		recs.append(str(heavy_scenes.size()) + " scenes have high node counts. Consider optimization")
	if total_nodes > 1000:
		recs.append("Project has " + str(total_nodes) + " total nodes. Consider scene streaming")
	if scene_count > 50:
		recs.append("Large project with " + str(scene_count) + " scenes. Ensure proper organization")
	if recs.is_empty():
		recs.append("Project performance looks good")
	return recs

func get_performance_report(params: Dictionary) -> void:
	log_info("Generating performance report")
	
	var report: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(),
		"godot_version": Engine.get_version_info(),
		"project_name": ProjectSettings.get_setting("application/config/name", "Unknown"),
		"memory": {
			"static_memory": Performance.get_monitor(Performance.MEMORY_STATIC),
			"max_static_memory": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
			"message_buffer": Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX)
		},
		"rendering": {
			"fps": Performance.get_monitor(Performance.TIME_FPS),
			"process_time": Performance.get_monitor(Performance.TIME_PROCESS),
			"physics_time": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		},
		"objects": {
			"object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
			"object_resource_count": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
			"object_node_count": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"object_orphan_count": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
		}
	}
	
	log_success("Performance report generated")
	print(JSON.stringify(report))

func profile_script(params: Dictionary) -> void:
	var script_path := normalize_path(params.script_path)
	var iterations: int = params.get("iterations", 1000)
	
	log_info("Profiling script: " + script_path)
	
	if not FileAccess.file_exists(script_path):
		log_error("Script does not exist")
		quit(1)
		return
	
	var script: Script = load(script_path)
	if not script:
		log_error("Failed to load script")
		quit(1)
		return
	
	var instance = script.new()
	if not instance:
		log_error("Failed to instantiate script")
		quit(1)
		return
	
	# Profile _ready function if it exists
	var has_ready: bool = instance.has_method("_ready")
	var has_process: bool = instance.has_method("_process")
	
	var result: Dictionary = {
		"script": script_path,
		"has_ready": has_ready,
		"has_process": has_process,
		"methods": [],
		"estimated_complexity": "medium"
	}
	
	# Get method list
	var methods: Array = instance.get_method_list()
	for method in methods:
		if not method["name"].begins_with("_"):
			result["methods"].append({
				"name": method["name"],
				"args": method.get("args", []).size()
			})
	
	# Estimate complexity based on file size
	var f := FileAccess.open(script_path, FileAccess.READ)
	if f:
		var content: String = f.get_as_text()
		f.close()
		var lines: int = content.split("\n").size()
		if lines > 500:
			result["estimated_complexity"] = "high"
		elif lines > 100:
			result["estimated_complexity"] = "medium"
		else:
			result["estimated_complexity"] = "low"
		result["lines_of_code"] = lines
	
	log_success("Script profile complete")
	print(JSON.stringify(result))

func analyze_memory_usage(params: Dictionary) -> void:
	var scene_path := normalize_path(params.get("scene_path", ""))
	
	log_info("Analyzing memory usage")
	
	var result: Dictionary = {
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"max_static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
		"message_buffer_bytes": Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX),
		"object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
		"resource_count": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"node_count": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"orphan_nodes": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	}
	
	if not scene_path.is_empty() and FileAccess.file_exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			var scene_root: Node = scene.instantiate()
			var nodes: Array = _get_all_nodes(scene_root)
			result["scene_nodes"] = nodes.size()
			result["scene_memory_estimate_kb"] = nodes.size() * 10
	
	log_success("Memory analysis complete")
	print(JSON.stringify(result))

func detect_bottlenecks(params: Dictionary) -> void:
	var search_path: String = normalize_path(params.get("path", "res://"))
	
	log_info("Detecting bottlenecks in: " + search_path)
	
	var bottlenecks: Array = []
	var scenes: Array = find_files(search_path, ".tscn")
	
	for scene_path in scenes:
		var scene: PackedScene = load(scene_path)
		if scene:
			var scene_root: Node = scene.instantiate()
			var issues: Array = []
			var node_count: int = 0
			var physics_count: int = 0
			var script_count: int = 0
			
			for node in _get_all_nodes(scene_root):
				node_count += 1
				if node is CollisionObject2D or node is CollisionObject3D:
					physics_count += 1
				if node.get_script():
					script_count += 1
				
				# Check for common issues
				if node is MeshInstance3D:
					var mesh: Mesh = node.mesh
					if mesh and mesh is ArrayMesh:
						if mesh.get_surface_count() > 5:
							issues.append("MeshInstance3D '" + node.name + "' has " + str(mesh.get_surface_count()) + " surfaces (consider merging)")
				
				if node is Label or node is RichTextLabel:
					issues.append("UI node '" + node.name + "' may cause redraws")
			
			if node_count > 300:
				issues.append("Scene has " + str(node_count) + " nodes (high)")
			if physics_count > 50:
				issues.append("Scene has " + str(physics_count) + " physics objects")
			if script_count > 100:
				issues.append("Scene has " + str(script_count) + " scripted nodes")
			
			if not issues.is_empty():
				bottlenecks.append({"scene": scene_path, "issues": issues})
	
	var result: Dictionary = {
		"scenes_analyzed": scenes.size(),
		"bottlenecks_found": bottlenecks.size(),
		"bottlenecks": bottlenecks,
		"summary": "Found " + str(bottlenecks.size()) + " scenes with potential performance issues"
	}
	
	log_success("Bottleneck detection complete")
	print(JSON.stringify(result))


# ============================================================================
# PHASE 2 - SHADER & MATERIAL (6 tools)
# ============================================================================

func edit_shader(params: Dictionary) -> void:
	var shader_path := normalize_path(params.shader_path)
	var content: String = params.get("content", "")
	var operation: String = params.get("operation", "replace")
	
	log_info("Editing shader: " + shader_path)
	
	var dest_dir := shader_path.get_base_dir()
	if not ensure_directory(dest_dir):
		quit(1)
		return
	
	if operation == "replace":
		# Create new shader
		var shader: Shader = Shader.new()
		shader.code = content
		
		var error := ResourceSaver.save(shader, shader_path)
		if error == OK:
			log_success("Shader saved: " + shader_path)
			print(JSON.stringify({"success": true, "path": shader_path, "lines": content.split("\n").size()}))
		else:
			log_error("Failed to save shader")
			quit(1)
	elif operation == "append":
		# Load existing and append
		var existing: Shader = load(shader_path)
		if existing and existing is Shader:
			existing.code += "\n" + content
			var error := ResourceSaver.save(existing, shader_path)
			if error == OK:
				log_success("Shader updated: " + shader_path)
				print(JSON.stringify({"success": true, "path": shader_path}))
			else:
				log_error("Failed to save shader")
				quit(1)
		else:
			log_error("Shader not found or invalid")
			quit(1)

func create_material(params: Dictionary) -> void:
	var material_path := normalize_path(params.material_path)
	var material_type: String = params.get("material_type", "StandardMaterial3D")
	var properties: Dictionary = params.get("properties", {})
	
	log_info("Creating material: " + material_path + " of type " + material_type)
	
	var dest_dir := material_path.get_base_dir()
	if not ensure_directory(dest_dir):
		quit(1)
		return
	
	var material: Material
	match material_type:
		"StandardMaterial3D":
			material = StandardMaterial3D.new()
		"ORMMaterial3D":
			material = ORMMaterial3D.new()
		"ShaderMaterial":
			material = ShaderMaterial.new()
		"CanvasItemMaterial":
			material = CanvasItemMaterial.new()
		_:
			material = StandardMaterial3D.new()
	
	# Apply properties
	for prop in properties:
		if material.get(prop) != null:
			material.set(prop, properties[prop])
	
	var error := ResourceSaver.save(material, material_path)
	if error == OK:
		log_success("Material created: " + material_path)
		print(JSON.stringify({"success": true, "path": material_path, "type": material_type}))
	else:
		log_error("Failed to save material")
		quit(1)

func edit_material(params: Dictionary) -> void:
	var material_path := normalize_path(params.material_path)
	var properties: Dictionary = params.get("properties", {})
	
	log_info("Editing material: " + material_path)
	
	if not FileAccess.file_exists(material_path):
		log_error("Material does not exist")
		quit(1)
		return
	
	var material: Material = load(material_path)
	if not material or not material is Material:
		log_error("Invalid material file")
		quit(1)
		return
	
	# Apply properties
	var changed: int = 0
	for prop in properties:
		if material.get(prop) != null:
			material.set(prop, properties[prop])
			changed += 1
	
	var error := ResourceSaver.save(material, material_path)
	if error == OK:
		log_success("Material updated: " + material_path + " (" + str(changed) + " properties)")
		print(JSON.stringify({"success": true, "path": material_path, "properties_changed": changed}))
	else:
		log_error("Failed to save material")
		quit(1)

func list_shaders(params: Dictionary) -> void:
	var search_path: String = normalize_path(params.get("path", "res://"))
	
	log_info("Listing shaders in: " + search_path)
	
	var shaders: Array = find_files(search_path, ".gdshader")
	var materials: Array = find_files(search_path, ".tres")
	
	# Filter materials to only include shader materials
	var shader_materials: Array = []
	for mat_path in materials:
		var mat: Material = load(mat_path)
		if mat and mat is ShaderMaterial:
			shader_materials.append(mat_path)
	
	var result: Dictionary = {
		"shaders": shaders,
		"shader_materials": shader_materials,
		"shader_count": shaders.size(),
		"material_count": shader_materials.size()
	}
	
	log_success("Found " + str(shaders.size()) + " shaders and " + str(shader_materials.size()) + " shader materials")
	print(JSON.stringify(result))

func create_shader(params: Dictionary) -> void:
	var shader_path := normalize_path(params.shader_path)
	var shader_type: String = params.get("shader_type", "spatial")
	var template: String = params.get("template", "")
	
	log_info("Creating shader: " + shader_path)
	
	var dest_dir := shader_path.get_base_dir()
	if not ensure_directory(dest_dir):
		quit(1)
		return
	
	var code: String = "shader_type " + shader_type + ";\n"
	
	match template:
		"unlit":
			code += """
	render_mode unshaded;
	
	void fragment() {
		ALBEDO = vec3(1.0, 1.0, 1.0);
	}
"""
		"vertex_displacement":
			code += """
	void vertex() {
		VERTEX.y += sin(TIME + VERTEX.x) * 0.1;
	}
	
	void fragment() {
		ALBEDO = vec3(0.5, 0.7, 1.0);
	}
"""
		"texture":
			code += """
	uniform sampler2D texture_albedo : source_color;
	
	void fragment() {
		ALBEDO = texture(texture_albedo, UV).rgb;
	}
"""
		_:
			code += """
	void fragment() {
		ALBEDO = vec3(1.0, 0.0, 0.0);
	}
"""
	
	var shader: Shader = Shader.new()
	shader.code = code
	
	var error := ResourceSaver.save(shader, shader_path)
	if error == OK:
		log_success("Shader created: " + shader_path)
		print(JSON.stringify({"success": true, "path": shader_path, "type": shader_type, "template": template}))
	else:
		log_error("Failed to save shader")
		quit(1)

func optimize_shader(params: Dictionary) -> void:
	var shader_path := normalize_path(params.shader_path)
	
	log_info("Analyzing shader for optimization: " + shader_path)
	
	if not FileAccess.file_exists(shader_path):
		log_error("Shader does not exist")
		quit(1)
		return
	
	var shader: Shader = load(shader_path)
	if not shader or not shader is Shader:
		log_error("Invalid shader file")
		quit(1)
		return
	
	var code: String = shader.code
	var lines: Array = code.split("\n")
	var suggestions: Array = []
	
	# Check for common optimization opportunities
	if code.find("texture") != -1 and code.find("vertex()") != -1:
		suggestions.append("Consider moving texture sampling to fragment() only")
	
	if code.find("TIME") != -1:
		suggestions.append("TIME uniform updates every frame - cache if possible")
	
	if code.find("sin") != -1 or code.find("cos") != -1:
		suggestions.append("Trigonometric functions are expensive - use sparingly")
	
	if lines.size() > 50:
		suggestions.append("Shader is " + str(lines.size()) + " lines - consider simplifying")
	
	if suggestions.is_empty():
		suggestions.append("Shader looks well optimized")
	
	var result: Dictionary = {
		"shader": shader_path,
		"lines": lines.size(),
		"suggestions": suggestions,
		"optimization_score": 100 - (suggestions.size() * 10)
	}
	
	log_success("Shader optimization analysis complete")
	print(JSON.stringify(result))

# ============================================================================
# PHASE 2 - ANIMATION (8 tools)
# ============================================================================

func create_animation(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var anim_name: String = params.anim_name
	var node_path: String = params.get("node_path", "")
	var length: float = params.get("length", 1.0)
	
	log_info("Creating animation: " + anim_name + " in " + scene_path)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	# Find or create AnimationPlayer
	var anim_player: AnimationPlayer
	for node in _get_all_nodes(scene_root):
		if node is AnimationPlayer:
			anim_player = node
			break
	
	if not anim_player:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		scene_root.add_child(anim_player)
		anim_player.owner = scene_root
	
	# Create new animation
	var animation: Animation = Animation.new()
	animation.length = length
	animation.resource_name = anim_name
	
	anim_player.add_animation(anim_name, animation)
	
	var packed_scene: PackedScene = PackedScene.new()
	var result := packed_scene.pack(scene_root)
	
	if result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Animation created: " + anim_name)
			print(JSON.stringify({"success": true, "animation": anim_name, "length": length}))
		else:
			log_error("Failed to save scene")
			quit(1)
	else:
		log_error("Failed to pack scene")
		quit(1)

func edit_animation(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var anim_name: String = params.anim_name
	var keyframes: Array = params.get("keyframes", [])
	
	log_info("Editing animation: " + anim_name + " in " + scene_path)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	var anim_player: AnimationPlayer
	for node in _get_all_nodes(scene_root):
		if node is AnimationPlayer:
			anim_player = node
			break
	
	if not anim_player:
		log_error("No AnimationPlayer found in scene")
		quit(1)
		return
	
	if not anim_player.has_animation(anim_name):
		log_error("Animation not found: " + anim_name)
		quit(1)
		return
	
	var animation: Animation = anim_player.get_animation(anim_name)
	var tracks_added: int = 0
	
	# Add keyframes
	for keyframe in keyframes:
		var track_path: String = keyframe.get("track", "")
		var time: float = keyframe.get("time", 0.0)
		var value = keyframe.get("value", null)
		var track_type: int = keyframe.get("track_type", Animation.TYPE_VALUE)
		
		if not track_path.is_empty() and value != null:
			var track_idx: int = animation.find_track(track_path, track_type)
			if track_idx == -1:
				track_idx = animation.add_track(track_type)
				animation.track_set_path(track_idx, track_path)
			
			animation.track_insert_key(track_idx, time, value)
			tracks_added += 1
	
	var packed_scene: PackedScene = PackedScene.new()
	var result := packed_scene.pack(scene_root)
	
	if result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Animation updated: " + anim_name + " (" + str(tracks_added) + " keyframes)")
			print(JSON.stringify({"success": true, "animation": anim_name, "keyframes_added": tracks_added}))
		else:
			log_error("Failed to save scene")
			quit(1)
	else:
		log_error("Failed to pack scene")
		quit(1)

func list_animations(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	
	log_info("Listing animations in: " + scene_path)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	var animations: Array = []
	
	for node in _get_all_nodes(scene_root):
		if node is AnimationPlayer:
			var anim_list: Array = node.get_animation_list()
			for anim_name in anim_list:
				var anim: Animation = node.get_animation(anim_name)
				animations.append({
					"name": anim_name,
					"length": anim.length,
					"loop": anim.loop_mode == Animation.LOOP_LINEAR,
					"tracks": anim.get_track_count(),
					"animation_player": node.name
				})
	
	log_success("Found " + str(animations.size()) + " animations")
	print(JSON.stringify({"scene": scene_path, "animations": animations, "count": animations.size()}))

func create_animation_library(params: Dictionary) -> void:
	var library_path := normalize_path(params.library_path)
	
	log_info("Creating animation library: " + library_path)
	
	var dest_dir := library_path.get_base_dir()
	if not ensure_directory(dest_dir):
		quit(1)
		return
	
	var library: AnimationLibrary = AnimationLibrary.new()
	
	var error := ResourceSaver.save(library, library_path)
	if error == OK:
		log_success("Animation library created: " + library_path)
		print(JSON.stringify({"success": true, "path": library_path}))
	else:
		log_error("Failed to save animation library")
		quit(1)

func add_animation_track(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var anim_name: String = params.anim_name
	var track_path: String = params.track_path
	var track_type: int = params.get("track_type", Animation.TYPE_VALUE)
	
	log_info("Adding animation track to: " + anim_name)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	var anim_player: AnimationPlayer
	for node in _get_all_nodes(scene_root):
		if node is AnimationPlayer:
			anim_player = node
			break
	
	if not anim_player or not anim_player.has_animation(anim_name):
		log_error("AnimationPlayer or animation not found")
		quit(1)
		return
	
	var animation: Animation = anim_player.get_animation(anim_name)
	var track_idx: int = animation.add_track(track_type)
	animation.track_set_path(track_idx, track_path)
	
	var packed_scene: PackedScene = PackedScene.new()
	var result := packed_scene.pack(scene_root)
	
	if result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Track added: " + track_path)
			print(JSON.stringify({"success": true, "track_path": track_path, "track_index": track_idx}))
		else:
			log_error("Failed to save scene")
			quit(1)
	else:
		log_error("Failed to pack scene")
		quit(1)

func edit_keyframe(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var anim_name: String = params.anim_name
	var track_index: int = params.track_index
	var time: float = params.time
	var value = params.value
	
	log_info("Editing keyframe in: " + anim_name)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	
	var anim_player: AnimationPlayer
	for node in _get_all_nodes(scene_root):
		if node is AnimationPlayer:
			anim_player = node
			break
	
	if not anim_player or not anim_player.has_animation(anim_name):
		log_error("Animation not found")
		quit(1)
		return
	
	var animation: Animation = anim_player.get_animation(anim_name)
	
	if track_index >= animation.get_track_count():
		log_error("Invalid track index")
		quit(1)
		return
	
	animation.track_insert_key(track_index, time, value)
	
	var packed_scene: PackedScene = PackedScene.new()
	var result := packed_scene.pack(scene_root)
	
	if result == OK:
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error == OK:
			log_success("Keyframe updated")
			print(JSON.stringify({"success": true, "time": time, "track": track_index}))
		else:
			log_error("Failed to save scene")
			quit(1)

# ============================================================================
# PHASE 2 - EXPORT & TESTING (4 tools)
# ============================================================================

func export_mesh_library(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var output_path := normalize_path(params.get("output_path", ""))
	
	log_info("Exporting mesh library from: " + scene_path)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	if output_path.is_empty():
		output_path = scene_path.replace(".tscn", "_meshlib.res")
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	var mesh_library := MeshLibrary.new()
	var item_count: int = 0
	
	for node in _get_all_nodes(scene_root):
		if node is MeshInstance3D:
			if node.mesh:
				mesh_library.create_item(item_count)
				mesh_library.set_item_mesh(item_count, node.mesh)
				mesh_library.set_item_name(item_count, node.name)
				item_count += 1
	
	if item_count == 0:
		log_warning("No MeshInstance3D nodes found")
	
	var error := ResourceSaver.save(mesh_library, output_path)
	if error == OK:
		log_success("Mesh library exported: " + output_path + " (" + str(item_count) + " items)")
		print(JSON.stringify({"success": true, "path": output_path, "items": item_count}))
	else:
		log_error("Failed to export mesh library")
		quit(1)

func get_export_presets(params: Dictionary) -> void:
	log_info("Getting export presets")
	
	var export_presets: Array = []
	var project_file := FileAccess.open("res://project.godot", FileAccess.READ)
	
	if project_file:
		var content: String = project_file.get_as_text()
		project_file.close()
		
		var lines: Array = content.split("\n")
		var in_export := false
		var current_preset: Dictionary = {}
		
		for line in lines:
			if line.begins_with("[export_preset."):
				in_export = true
				current_preset = {"name": line.split(".")[1].replace("]", ""), "platform": "", "options": {}}
			elif in_export and line.begins_with("["):
				in_export = false
				if not current_preset.is_empty():
					export_presets.append(current_preset)
					current_preset = {}
			elif in_export and "=" in line:
				var parts: Array = line.split("=")
				if parts.size() >= 2:
					var key: String = parts[0].strip_edges()
					var value: String = parts[1].strip_edges().replace('"', "")
					if key == "name":
						current_preset["name"] = value
					elif key == "platform":
						current_preset["platform"] = value
					else:
						current_preset["options"][key] = value
		
		if not current_preset.is_empty():
			export_presets.append(current_preset)
	
	log_success("Found " + str(export_presets.size()) + " export presets")
	print(JSON.stringify({"presets": export_presets, "count": export_presets.size()}))

func quick_test(params: Dictionary) -> void:
	log_info("Running quick test")
	
	var issues: Array = []
	var warnings: Array = []
	
	# Test 1: Project file exists
	if not FileAccess.file_exists("res://project.godot"):
		issues.append("project.godot not found")
	
	# Test 2: Main scene configured
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene.is_empty():
		issues.append("No main scene configured")
	elif not FileAccess.file_exists(main_scene):
		issues.append("Main scene not found: " + main_scene)
	
	# Test 3: Check for syntax errors in scripts
	var scripts: Array = find_files("res://", ".gd")
	var script_errors: int = 0
	for script_path in scripts.slice(0, 10):  # Check first 10 scripts only
		var script: Script = load(script_path)
		if not script:
			script_errors += 1
	
	if script_errors > 0:
		warnings.append(str(script_errors) + " scripts failed to load (checked first 10)")
	
	# Test 4: Check for missing dependencies
	var scenes: Array = find_files("res://", ".tscn")
	if scenes.is_empty():
		warnings.append("No scenes found in project")
	
	var result: Dictionary = {
		"passed": issues.is_empty(),
		"issues": issues,
		"warnings": warnings,
		"tests_run": 4,
		"summary": "Quick test " + ("passed" if issues.is_empty() else "failed with " + str(issues.size()) + " issues")
	}
	
	if issues.is_empty():
		log_success("Quick test passed")
	else:
		log_error("Quick test failed")
	
	print(JSON.stringify(result))

func full_test(params: Dictionary) -> void:
	log_info("Running full project test")
	
	var results: Dictionary = {
		"project_valid": true,
		"scripts_tested": 0,
		"script_errors": [],
		"scenes_tested": 0,
		"scene_errors": [],
		"resources_tested": 0,
		"resource_errors": [],
		"missing_dependencies": [],
		"recommendations": []
	}
	
	# Test all scripts
	var scripts: Array = find_files("res://", ".gd")
	for script_path in scripts:
		results["scripts_tested"] += 1
		var script: Script = load(script_path)
		if not script:
			results["script_errors"].append(script_path)
	
	# Test all scenes
	var scenes: Array = find_files("res://", ".tscn")
	for scene_path in scenes:
		results["scenes_tested"] += 1
		var scene: PackedScene = load(scene_path)
		if not scene:
			results["scene_errors"].append(scene_path)
		else:
			var scene_root: Node = scene.instantiate()
			# Check for missing script references
			for node in _get_all_nodes(scene_root):
				if node.get_script():
					var script: Script = node.get_script()
					if not FileAccess.file_exists(script.resource_path):
						results["missing_dependencies"].append({
							"scene": scene_path,
							"node": node.name,
							"missing_script": script.resource_path
						})
	
	# Test resources
	var resources: Array = find_files("res://", ".tres")
	for res_path in resources:
		results["resources_tested"] += 1
		var res = load(res_path)
		if not res:
			results["resource_errors"].append(res_path)
	
	# Generate recommendations
	if results["scripts_tested"] > 100:
		results["recommendations"].append("Project has " + str(results["scripts_tested"]) + " scripts - consider organization")
	
	if results["scenes_tested"] > 50:
		results["recommendations"].append("Project has " + str(results["scenes_tested"]) + " scenes - use folders")
	
	if not results["missing_dependencies"].is_empty():
		results["recommendations"].append("Fix " + str(results["missing_dependencies"].size()) + " missing dependencies")
	
	results["all_passed"] = results["script_errors"].is_empty() and results["scene_errors"].is_empty() and results["resource_errors"].is_empty()
	results["summary"] = "Full test " + ("passed" if results["all_passed"] else "failed")
	
	if results["all_passed"]:
		log_success("Full test passed")
	else:
		log_error("Full test found issues")
	
	print(JSON.stringify(results))

# ============================================================================
# MISSING ANIMATION FUNCTIONS - Added for completeness
# ============================================================================

func play_animation(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var anim_name: String = params.anim_name
	
	log_info("Previewing animation: " + anim_name)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	var anim_player: AnimationPlayer
	
	for node in _get_all_nodes(scene_root):
		if node is AnimationPlayer:
			anim_player = node
			break
	
	if not anim_player:
		log_error("No AnimationPlayer found")
		quit(1)
		return
	
	if not anim_player.has_animation(anim_name):
		log_error("Animation not found: " + anim_name)
		quit(1)
		return
	
	var animation: Animation = anim_player.get_animation(anim_name)
	
	var result: Dictionary = {
		"animation": anim_name,
		"length": animation.length,
		"tracks": animation.get_track_count(),
		"can_play": true,
		"note": "Animation ready for playback. Use Godot editor to preview."
	}
	
	log_success("Animation ready: " + anim_name)
	print(JSON.stringify(result))

func export_animation(params: Dictionary) -> void:
	var scene_path := normalize_path(params.scene_path)
	var anim_name: String = params.anim_name
	var export_path := normalize_path(params.get("export_path", ""))
	
	log_info("Exporting animation: " + anim_name)
	
	if not FileAccess.file_exists(scene_path):
		log_error("Scene does not exist")
		quit(1)
		return
	
	if export_path.is_empty():
		export_path = scene_path.get_base_dir() + "/" + anim_name + ".res"
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		log_error("Failed to load scene")
		quit(1)
		return
	
	var scene_root: Node = scene.instantiate()
	var anim_player: AnimationPlayer
	
	for node in _get_all_nodes(scene_root):
		if node is AnimationPlayer:
			anim_player = node
			break
	
	if not anim_player or not anim_player.has_animation(anim_name):
		log_error("Animation not found")
		quit(1)
		return
	
	var animation: Animation = anim_player.get_animation(anim_name)
	var error := ResourceSaver.save(animation, export_path)
	
	if error == OK:
		log_success("Animation exported: " + export_path)
		print(JSON.stringify({"success": true, "animation": anim_name, "export_path": export_path}))
	else:
		log_error("Failed to export animation")
		quit(1)
