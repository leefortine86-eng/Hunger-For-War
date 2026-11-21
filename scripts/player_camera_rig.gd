extends Camera3D
class_name PlayerCameraRig

@export var standing_height: float = 1.55
@export var crouching_height: float = 1.05
@export var prone_height: float = 0.48
@export var stance_smoothing: float = 14.0
@export var hip_fov: float = 75.0
@export var aimed_fov: float = 48.0
@export var fov_smoothing: float = 100.0

var target_height: float = 1.55
var aiming: bool = false

func set_stance(prone: bool, crouching: bool) -> void:
    if prone:
        target_height = prone_height
    elif crouching:
        target_height = crouching_height
    else:
        target_height = standing_height

func set_aiming(enabled: bool) -> void:
    aiming = enabled

func _process(delta: float) -> void:
    position.y = move_toward(position.y, target_height, stance_smoothing * delta)
    var target_fov := aimed_fov if aiming else hip_fov
    fov = move_toward(fov, target_fov, fov_smoothing * delta)
