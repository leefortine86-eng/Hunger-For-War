extends Node
class_name PlayerMovement

@export var body_path: NodePath = NodePath("..")
@export var collision_path: NodePath = NodePath("../CollisionShape3D")
@export_group("Movement")
@export var walk_speed: float = 7.0
@export var sprint_multiplier: float = 1.55
@export var crouch_multiplier: float = 0.45
@export var prone_multiplier: float = 0.20
@export var ground_acceleration: float = 0.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 20.0
@export_group("Stance collision")
@export var standing_height: float = 1.8
@export var crouching_height: float = 1.2
@export var prone_height: float = 0.65
@export var stance_speed: float = 3.0

var body: CharacterBody3D
var collision: CollisionShape3D

func _ready() -> void:
    body = get_node_or_null(body_path) as CharacterBody3D
    collision = get_node_or_null(collision_path) as CollisionShape3D
    if body == null or collision == null:
        push_error("PlayerMovement requires a CharacterBody3D and CollisionShape3D.")
        set_physics_process(false)
        return
    if collision.shape is CapsuleShape3D:
        collision.shape = collision.shape.duplicate()

func physics_step(delta: float, input_dir: Vector2, sprinting: bool, crouching: bool, prone: bool, jump_requested: bool) -> void:
    if body == null:
        return

    var local_direction := Vector3(input_dir.x, 0.0, input_dir.y)
    var direction := (body.global_transform.basis * local_direction).normalized()
    var speed := walk_speed
    if prone:
        speed *= prone_multiplier
    elif crouching:
        speed *= crouch_multiplier
    elif sprinting:
        speed *= sprint_multiplier

    if ground_acceleration > 0.0:
        body.velocity.x = move_toward(body.velocity.x, direction.x * speed, ground_acceleration * delta)
        body.velocity.z = move_toward(body.velocity.z, direction.z * speed, ground_acceleration * delta)
    else:
        body.velocity.x = direction.x * speed
        body.velocity.z = direction.z * speed

    if body.is_on_floor():
        if body.velocity.y < 0.0:
            body.velocity.y = 0.0
        if jump_requested and not crouching and not prone:
            body.velocity.y = jump_velocity
    else:
        body.velocity.y -= gravity * delta

    _update_collision_height(delta, prone, crouching)
    body.move_and_slide()

func _update_collision_height(delta: float, prone: bool, crouching: bool) -> void:
    if collision == null:
        return
    var capsule := collision.shape as CapsuleShape3D
    if capsule == null:
        return
    var target_height := standing_height
    if prone:
        target_height = prone_height
    elif crouching:
        target_height = crouching_height
    capsule.height = move_toward(capsule.height, target_height, stance_speed * delta)
    collision.position.y = capsule.height * 0.5
