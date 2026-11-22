extends Node
class_name TacticalPlayerController
## Coordinates the player body with independent movement and camera components.
## Input collection and presentation remain owned by the player input/UI layer.

@export var movement_path: NodePath = NodePath("../Movement")
@export var camera_path: NodePath = NodePath("../Camera3D")
@export var collision_path: NodePath = NodePath("../CollisionShape3D")
@export var stance_clearance_margin: float = 0.02

var _body: CharacterBody3D
var _movement: PlayerMovement
var _camera: PlayerCameraRig
var _collision: CollisionShape3D
var _initialized: bool = false

func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	_movement = get_node_or_null(movement_path) as PlayerMovement
	_camera = get_node_or_null(camera_path) as PlayerCameraRig
	_collision = get_node_or_null(collision_path) as CollisionShape3D

	if _body == null:
		push_error("TacticalPlayerController must be a child of CharacterBody3D.")
		set_physics_process(false)
		return
	if _movement == null:
		push_error("TacticalPlayerController could not find its PlayerMovement component.")
		set_physics_process(false)
		return
	if _camera == null:
		push_error("TacticalPlayerController could not find its PlayerCameraRig.")
		set_physics_process(false)
		return
	if _collision == null or not (_collision.shape is CapsuleShape3D):
		push_error("TacticalPlayerController requires a CapsuleShape3D at collision_path.")
		set_physics_process(false)
		return

	_initialized = true

## Advances the complete player simulation for one physics frame.
## input_direction is local input: x = strafe, y = forward/back.
func physics_step(
	delta: float,
	input_direction: Vector2,
	wants_sprint: bool,
	wants_crouch: bool,
	wants_prone: bool,
	jump_requested: bool
) -> void:
	if not _initialized:
		return

	var normalized_input: Vector2 = input_direction.limit_length(1.0)
	var capsule: CapsuleShape3D = _collision.shape as CapsuleShape3D
	var previous_height: float = capsule.height

	_movement.physics_step(
		delta,
		normalized_input,
		wants_sprint,
		wants_crouch,
		wants_prone,
		jump_requested
	)

	# Godot capsules cannot be shorter than their diameter.
	var minimum_height: float = capsule.radius * 2.0
	if capsule.height < minimum_height:
		capsule.height = minimum_height

	# If a stance increase intersects a ceiling or other obstacle, restore
	# the previous safe height. The collision bottom remains at the feet.
	if capsule.height > previous_height + 0.001:
		if not _can_fit_capsule_height(capsule.height):
			capsule.height = previous_height

	_collision.position.y = capsule.height * 0.5

	# Drive camera stance from the collision shape that actually fits,
	# rather than from the requested input. This prevents camera/stance drift.
	var prone_threshold: float = 0.5 * (_movement.prone_height + _movement.crouching_height)
	var crouch_threshold: float = 0.5 * (_movement.crouching_height + _movement.standing_height)
	var actual_prone: bool = capsule.height < prone_threshold
	var actual_crouching: bool = (
		not actual_prone and capsule.height < crouch_threshold
	)
	_camera.set_stance(actual_prone, actual_crouching)

	var horizontal_velocity := Vector2(_body.velocity.x, _body.velocity.z)
	_camera.set_motion_state(
		horizontal_velocity.length(),
		_movement.get_fatigue_ratio()
	)

func _can_fit_capsule_height(target_height: float) -> bool:
	var current_capsule: CapsuleShape3D = _collision.shape as CapsuleShape3D
	if current_capsule == null:
		return false

	var test_capsule := current_capsule.duplicate() as CapsuleShape3D
	test_capsule.height = maxf(target_height, test_capsule.radius * 2.0)

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = test_capsule
	query.transform = _collision.global_transform
	query.transform.origin = _body.global_position + Vector3(
		0.0,
		test_capsule.height * 0.5,
		0.0
	)
	query.collision_mask = _body.collision_mask
	query.exclude = [_body.get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.margin = maxf(stance_clearance_margin, 0.001)

	var space_state: PhysicsDirectSpaceState3D = (
		_body.get_world_3d().direct_space_state
	)
	return space_state.intersect_shape(query, 1).is_empty()

func get_stamina_ratio() -> float:
	if not _initialized:
		return 0.0
	return _movement.get_stamina_ratio()

func get_fatigue_ratio() -> float:
	if not _initialized:
		return 0.0
	return _movement.get_fatigue_ratio()

func is_ready_for_gameplay() -> bool:
	return _initialized
