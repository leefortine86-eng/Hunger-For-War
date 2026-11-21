extends Camera3D
class_name PlayerCameraRig

@export var standing_height: float = 1.55
@export var crouching_height: float = 1.05
@export var prone_height: float = 0.48
@export var stance_smoothing: float = 14.0
@export var hip_fov: float = 75.0
@export var aimed_fov: float = 48.0
@export var fov_smoothing: float = 100.0
@export_group("Weapon inertia and bob")
@export var weapon_path: NodePath = NodePath("../Weapon")
@export var look_inertia_strength: float = 0.0018
@export var movement_bob_frequency: float = 8.0
@export var movement_bob_amplitude: float = 0.018
@export var weapon_lag_smoothing: float = 10.0
@export var aim_sway_strength: float = 0.0007
@export var fatigue_sway_multiplier: float = 2.5

var target_height: float = 1.55
var aiming: bool = false
var _weapon: Node3D
var _weapon_home_position: Vector3
var _look_lag := Vector2.ZERO
var _look_motion := Vector2.ZERO
var _horizontal_speed: float = 0.0
var _fatigue: float = 0.0
var _bob_time: float = 0.0

func set_stance(prone: bool, crouching: bool) -> void:
    if prone:
        target_height = prone_height
    elif crouching:
        target_height = crouching_height
    else:
        target_height = standing_height

func set_aiming(enabled: bool) -> void:
    aiming = enabled

func feed_look_motion(relative_motion: Vector2) -> void:
    _look_motion += relative_motion

func set_motion_state(horizontal_speed: float, fatigue_ratio: float) -> void:
    _horizontal_speed = horizontal_speed
    _fatigue = clampf(fatigue_ratio, 0.0, 1.0)

func _process(delta: float) -> void:
    position.y = move_toward(position.y, target_height, stance_smoothing * delta)
    var target_fov := aimed_fov if aiming else hip_fov
    fov = move_toward(fov, target_fov, fov_smoothing * delta)

    var lag_target := Vector2(-_look_motion.x, _look_motion.y) * look_inertia_strength
    _look_lag = _look_lag.lerp(lag_target, clampf(weapon_lag_smoothing * delta, 0.0, 1.0))
    _look_motion = _look_motion.lerp(Vector2.ZERO, clampf(18.0 * delta, 0.0, 1.0))

    var fatigue_scale := 1.0 + _fatigue * fatigue_sway_multiplier
    var sway := Vector3.ZERO
    if aiming:
        sway.x = sin(Time.get_ticks_msec() * 0.0017) * aim_sway_strength * fatigue_scale
        sway.y = cos(Time.get_ticks_msec() * 0.0013) * aim_sway_strength * fatigue_scale

    _bob_time += delta * (movement_bob_frequency + _horizontal_speed * 0.8)
    var movement_amount := clampf(_horizontal_speed / 6.5, 0.0, 1.0)
    var bob := Vector3(cos(_bob_time * 0.5) * movement_bob_amplitude * movement_amount, absf(sin(_bob_time)) * movement_bob_amplitude * movement_amount, 0.0)
    if _weapon != null:
        var target_position := _weapon_home_position + bob + sway + Vector3(_look_lag.x, _look_lag.y, 0.0)
        _weapon.position = _weapon.position.lerp(target_position, clampf(weapon_lag_smoothing * delta, 0.0, 1.0))
