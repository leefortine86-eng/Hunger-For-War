extends Node
class_name PlayerMovement

@export var body_path: NodePath = NodePath("..")
@export var collision_path: NodePath = NodePath("../CollisionShape3D")
@export_group("Movement")
@export var tactical_walk_speed: float = 3.2
@export var sprint_speed: float = 6.5
@export var crouch_speed: float = 1.8
@export var prone_speed: float = 0.8
@export var acceleration: float = 7.0
@export var deceleration: float = 10.0
@export var air_control: float = 2.5
@export var jump_velocity: float = 5.2
@export var gravity: float = 20.0
@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var sprint_stamina_drain: float = 18.0
@export var movement_stamina_drain: float = 2.0
@export var stamina_recovery: float = 12.0
@export var stamina_recovery_delay: float = 1.25
@export var exhausted_sprint_multiplier: float = 0.72
@export_group("Stance collision")
@export var standing_height: float = 1.8
@export var crouching_height: float = 1.2
@export var prone_height: float = 0.65
@export var stance_speed: float = 3.0

var body: CharacterBody3D
var collision: CollisionShape3D
var stamina: float = 100.0
var fatigue_ratio: float = 0.0
var _recovery_timer: float = 0.0

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
    var wants_sprint := sprinting and not crouching and not prone and input_dir.length() > 0.1
    if wants_sprint and stamina > 0.0:
        stamina = maxf(stamina - sprint_stamina_drain * delta, 0.0)
        _recovery_timer = stamina_recovery_delay
    else:
        if input_dir.length() > 0.1 and body.is_on_floor():
            stamina = maxf(stamina - movement_stamina_drain * delta, 0.0)
            _recovery_timer = maxf(_recovery_timer, 0.25)
        else:
            _recovery_timer = maxf(_recovery_timer - delta, 0.0)
            if _recovery_timer <= 0.0:
                stamina = minf(stamina + stamina_recovery * delta, max_stamina)

    fatigue_ratio = 1.0 - (stamina / maxf(max_stamina, 0.001))
    var speed := tactical_walk_speed
    if prone:
        speed = prone_speed
    elif crouching:
        speed = crouch_speed
    elif wants_sprint and stamina > 0.0:
        speed = sprint_speed
    elif wants_sprint and stamina <= 0.0:
        speed = tactical_walk_speed * exhausted_sprint_multiplier

    var target_velocity := direction * speed
    var horizontal_velocity := Vector3(body.velocity.x, 0.0, body.velocity.z)
    var rate := acceleration if direction.length() > 0.01 else deceleration
    if not body.is_on_floor():
        rate = air_control
    horizontal_velocity = horizontal_velocity.move_toward(target_velocity, rate * delta)
    body.velocity.x = horizontal_velocity.x
    body.velocity.z = horizontal_velocity.z

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

func get_stamina_ratio() -> float:
    return clampf(stamina / maxf(max_stamina, 0.001), 0.0, 1.0)

func get_fatigue_ratio() -> float:
    return fatigue_ratio
