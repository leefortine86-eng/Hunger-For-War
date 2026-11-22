extends SceneTree

var _script_paths: Array[String] = []
var _errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_collect_scripts("res://")
	_script_paths.sort()

	for script_path in _script_paths:
		var resource: Resource = ResourceLoader.load(
			script_path,
			"GDScript",
			ResourceLoader.CACHE_MODE_IGNORE
		)
		if resource == null or not (resource is GDScript):
			_errors.append("%s: failed to load as GDScript" % script_path)
			continue

		var script := resource as GDScript
		var reload_error: Error = script.reload()
		if reload_error != OK:
			_errors.append("%s: GDScript reload returned %s" % [script_path, error_string(reload_error)])

	if _errors.is_empty():
		print("GDSCRIPT_PARSE_TEST: PASS (", _script_paths.size(), " scripts checked)")
		quit(0)
	else:
		for message in _errors:
			push_error(message)
		push_error("GDSCRIPT_PARSE_TEST: ", _errors.size(), " errors across ", _script_paths.size(), " scripts")
		quit(1)

func _collect_scripts(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		_errors.append("Unable to open directory: %s" % directory_path)
		return

	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry == "." or entry == "..":
			entry = directory.get_next()
			continue

		var full_path := directory_path.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with("."):
				_collect_scripts(full_path)
		elif entry.ends_with(".gd"):
			_script_paths.append(full_path)

		entry = directory.get_next()
	directory.list_dir_end()
