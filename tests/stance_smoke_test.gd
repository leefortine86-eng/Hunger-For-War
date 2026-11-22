extends SceneTree

const PLAYER_MOVEMENT = preload("res://scripts/player_movement.gd")
const PLAYER_CONTROLLER = preload("res://scripts/player_controller.gd")
const PLAYER_CAMERA = preload("res://scripts/player_camera_rig.gd")

var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var floor_body := StaticBody3D.new()
	floor_body.name = "TestFloor"
	world.add_child(floor_body)
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(20.0, 0.2, 20.0)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position.y = -0.1

	var player := CharacterBody3D.new()
	player.name = "TestPlayer"
	player.collision_layer = 1
	player.collision_mask = 1
	world.add_child(player)

	var initial_capsule := CapsuleShape3D.new()
	initial_capsule.radius = 0.4
	initial_capsule.height = 1.8
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = initial_capsule
	collision.position.y = 0.9
	player.add_child(collision)

	var movement := Node.new()
	movement.name = "Movement"
	movement.set_script(PLAYER_MOVEMENT)
	player.add_child(movement)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.set_script(PLAYER_CAMERA)
	var test_weapon := Node3D.new()
	test_weapon.name = "Weapon"
	camera.add_child(test_weapon)
	player.add_child(camera)

	var controller: Node = PLAYER_CONTROLLER.new()
	controller.name = "Controller"
	player.add_child(controller)

	await process_frame
	await physics_frame
	await process_frame

	var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
	_expect(bool(controller.call("is_ready_for_gameplay")), "controller initializes with required components")
	_expect(is_equal_approx(capsule.height, 1.8), "initial standing capsule height is 1.8 m")

	controller.call("physics_step", 0.5, Vector2.ZERO, false, false, true, false)
	_expect(capsule.height >= capsule.radius * 2.0 - 0.001, "prone capsule respects the 0.8 m diameter minimum")
	_expect(capsule.height <= 0.81, "prone capsule settles at the legal minimum")
	_expect(is_equal_approx(collision.position.y, capsule.height * 0.5), "prone collision stays grounded at the feet")
	_expect(is_equal_approx(float(camera.get("target_height")), float(camera.get("prone_height"))), "camera follows the actual prone collision stance")
	camera.call("_process", 1.0)
	_expect(is_equal_approx(camera.position.y, float(camera.get("prone_height"))), "camera physically reaches prone eye height")

	controller.call("physics_step", 0.5, Vector2.ZERO, false, true, false, false)
	_expect(capsule.height > 0.8 and capsule.height <= 1.21, "prone-to-crouch transition reaches crouch height")
	_expect(is_equal_approx(float(camera.get("target_height")), float(camera.get("crouching_height"))), "camera follows crouch collision height")
	camera.call("_process", 1.0)
	_expect(is_equal_approx(camera.position.y, float(camera.get("crouching_height"))), "camera physically reaches crouched eye height")

	controller.call("physics_step", 0.5, Vector2.ZERO, false, false, false, false)
	_expect(capsule.height >= 1.79, "crouch-to-stand transition reaches standing height")
	_expect(is_equal_approx(float(camera.get("target_height")), float(camera.get("standing_height"))), "camera follows standing collision height")
	camera.call("_process", 1.0)
	_expect(is_equal_approx(camera.position.y, float(camera.get("standing_height"))), "camera physically reaches standing eye height")

	# Enter crouch first, then place a low ceiling just above the crouched capsule.
	controller.call("physics_step", 0.5, Vector2.ZERO, false, true, false, false)
	var safe_crouch_height: float = capsule.height
	var safe_body_position: Vector3 = player.global_position

	var ceiling_body := StaticBody3D.new()
	ceiling_body.name = "TestCeiling"
	world.add_child(ceiling_body)
	var ceiling_shape := CollisionShape3D.new()
	var ceiling_box := BoxShape3D.new()
	ceiling_box.size = Vector3(4.0, 0.2, 4.0)
	ceiling_shape.shape = ceiling_box
	ceiling_body.add_child(ceiling_shape)
	ceiling_body.position.y = 1.35

	controller.call("physics_step", 0.5, Vector2.ZERO, false, false, false, false)
	_expect(capsule.height <= safe_crouch_height + 0.01, "ceiling blocks unsafe stand-up collision expansion")
	_expect(is_equal_approx(collision.position.y, capsule.height * 0.5), "collision remains centered after blocked transition")
	_expect(player.global_position.distance_to(safe_body_position) < 0.05, "blocked stance transition does not push player through the floor")
	_expect(is_equal_approx(float(camera.get("target_height")), float(camera.get("crouching_height"))), "camera remains at the safe crouched stance")
	camera.call("_process", 1.0)
	_expect(is_equal_approx(camera.position.y, float(camera.get("crouching_height"))), "camera stays at safe crouched eye height under the ceiling")

	if _failures == 0:
		print("STANCE_SMOKE_TEST: PASS (", _checks, " checks)")
		quit(0)
	else:
		push_error("STANCE_SMOKE_TEST: ", _failures, " of ", _checks, " checks failed")
		quit(1)

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: ", description)
