extends SceneTree

func _initialize() -> void:
	var own_path: String = get_script().resource_path
	var broken: int = 0
	var total: int = 0

	for script_path in _gd_files("res://"):
		if script_path == own_path:
			continue
		total += 1
		var script := load(script_path) as Script
		if script == null or not script.can_instantiate():
			broken += 1
			printerr("BROKEN: ", script_path)

	print("GDSCRIPT_PARSE_TEST: checked ", total, " scripts; broken: ", broken)
	quit(1 if broken > 0 else 0)

func _gd_files(directory_path: String) -> PackedStringArray:
	var paths := PackedStringArray()
	if FileAccess.file_exists(directory_path.path_join(".gdignore")):
		return paths

	for file_name in DirAccess.get_files_at(directory_path):
		if file_name.get_extension() == "gd":
			paths.append(directory_path.path_join(file_name))

	for subdirectory in DirAccess.get_directories_at(directory_path):
		if not subdirectory.begins_with("."):
			paths.append_array(_gd_files(directory_path.path_join(subdirectory)))

	return paths
