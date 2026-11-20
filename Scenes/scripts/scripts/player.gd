

extends CharacterBody3D

@export var move_speed: float = 7.0
@export var mouse_sensitivity: float = 0.002

var gravity: float = 20.0

@onready var camera = $Camera3D

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotate_x(-event.relative.y * mouse_sensitivity)
        camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)

    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
    var input_dir = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    )

    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0

    move_and_slide()
