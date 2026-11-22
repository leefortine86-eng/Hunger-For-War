extends Node
class_name TacticalPlayerController
## Coordinates the player body with independent movement and camera components.
## Input collection and presentation remain owned by the player input/UI layer.

@export var movement_path: NodePath = NodePath("../Movement")
@export var camera_path: NodePath = NodePath("../Camera3D")

var _body: CharacterBody3D
var _movement: PlayerMovement
var _camera: PlayerCameraRig
var _initialized: bool = false

func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	_movement = get_node_or_null(movement_path) as PlayerMovement
	_camera = get_node_or_null(camera_path) as PlayerCameraRig

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

	var normalized_input := input_direction.limit_length(1.0)
	_movement.physics_step(
		delta,
		normalized_input,
		wants_sprint,
		wants_crouch,
		wants_prone,
		jump_requested
	)

	var horizontal_velocity := Vector2(_body.velocity.x, _body.velocity.z)
	_camera.set_stance(wants_prone, wants_crouch)
	_camera.set_motion_state(
		horizontal_velocity.length(),
		_movement.get_fatigue_ratio()
	)

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
