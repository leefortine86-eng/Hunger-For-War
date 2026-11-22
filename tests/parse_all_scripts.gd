extends SceneTree

const SCRIPT_PATHS: Array[String] = [
	"res://scripts/ally.gd",
	"res://scripts/enemy.gd",
	"res://scripts/explosive_projectile.gd",
	"res://scripts/game/game_session.gd",
	"res://scripts/glb_soldier_animator.gd",
	"res://scripts/main.gd",
	"res://scripts/player.gd",
	"res://scripts/player_camera_rig.gd",
	"res://scripts/player_controller.gd",
	"res://scripts/player_movement.gd",
	"res://scripts/soldier_pose_rig.gd",
	"res://scripts/soldier_skeleton_rig.gd",
	"res://scripts/weapon.gd",
	"res://scripts/weapon_catalog.gd",
	"res://tests/parse_all_scripts.gd",
	"res://tests/stance_smoke_test.gd"
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	for script_path in SCRIPT_PATHS:
		var resource: Resource = ResourceLoader.load(
			script_path,
			"GDScript",
			ResourceLoader.CACHE_MODE_IGNORE
		)
		if resource == null or not (resource is GDScript):
			errors.append("%s: failed to compile or load" % script_path)
			continue
		var script := resource as GDScript
		if not script.can_instantiate():
			errors.append("%s: script cannot instantiate" % script_path)

	if errors.is_empty():
		print("GDSCRIPT_PARSE_TEST: PASS (", SCRIPT_PATHS.size(), " scripts checked)")
		quit(0)
	else:
		for message in errors:
			push_error(message)
		push_error("GDSCRIPT_PARSE_TEST: ", errors.size(), " failures across ", SCRIPT_PATHS.size(), " scripts")
		quit(1)
