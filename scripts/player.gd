extends CharacterBody3D

@export var move_speed: float = 7.0
@export var mouse_sensitivity: float = 0.002
@export var touch_sensitivity: float = 0.004

var gravity: float = 20.0
var mobile_move := Vector2.ZERO
var joystick_touch_id := -1
var look_touch_id := -1
var joystick_center := Vector2.ZERO
var joystick_radius: float = 58.0

@onready var camera = $Camera3D
@onready var weapon = $Camera3D/Weapon
@onready var raycast = $Camera3D/RayCast3D

var touch_overlay: Control
var joystick_base: Panel
var joystick_knob: Panel

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _create_mobile_controls()

func _create_mobile_controls():
    touch_overlay = Control.new()
    touch_overlay.name = "MobileControls"
    touch_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    touch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var canvas := CanvasLayer.new()
    canvas.name = "MobileControlsLayer"
    add_child(canvas)
    canvas.add_child(touch_overlay)

    var screen_size := get_viewport().get_visible_rect().size
    joystick_base = Panel.new()
    joystick_base.name = "JoystickBase"
    joystick_base.position = Vector2(32, screen_size.y - 184)
    joystick_base.size = Vector2(144, 144)
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var base_style := StyleBoxFlat.new()
    base_style.bg_color = Color(0.12, 0.16, 0.20, 0.48)
    base_style.set_corner_radius_all(72)
    base_style.border_width_left = 2
    base_style.border_width_top = 2
    base_style.border_width_right = 2
    base_style.border_width_bottom = 2
    base_style.border_color = Color(0.85, 0.9, 0.95, 0.65)
    joystick_base.add_theme_stylebox_override("panel", base_style)
    touch_overlay.add_child(joystick_base)

    joystick_center = joystick_base.position + joystick_base.size / 2.0
    joystick_knob = Panel.new()
    joystick_knob.name = "JoystickKnob"
    joystick_knob.position = joystick_center - Vector2(29, 29)
    joystick_knob.size = Vector2(58, 58)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var knob_style := StyleBoxFlat.new()
    knob_style.bg_color = Color(0.72, 0.82, 0.9, 0.78)
    knob_style.set_corner_radius_all(29)
    joystick_knob.add_theme_stylebox_override("panel", knob_style)
    touch_overlay.add_child(joystick_knob)

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            var screen_width := get_viewport().get_visible_rect().size.x
            if event.position.x < screen_width * 0.5 and joystick_touch_id == -1:
                if event.position.distance_to(joystick_center) <= 115.0:
                    joystick_touch_id = event.index
                    _update_joystick(event.position)
            elif event.position.x >= screen_width * 0.5 and look_touch_id == -1:
                look_touch_id = event.index
        else:
            if event.index == joystick_touch_id:
                joystick_touch_id = -1
                mobile_move = Vector2.ZERO
                joystick_knob.position = joystick_center - joystick_knob.size / 2.0
            if event.index == look_touch_id:
                look_touch_id = -1

    elif event is InputEventScreenDrag:
        if event.index == joystick_touch_id:
            _update_joystick(event.position)
        elif event.index == look_touch_id:
            _rotate_camera(event.relative, touch_sensitivity)

func _update_joystick(touch_position: Vector2):
    var offset: Vector2 = touch_position - joystick_center
    if offset.length() > joystick_radius:
        offset = offset.normalized() * joystick_radius
    mobile_move = offset / joystick_radius
    joystick_knob.position = joystick_center + offset - joystick_knob.size / 2.0

func _rotate_camera(relative_motion: Vector2, sensitivity: float):
    rotate_y(-relative_motion.x * sensitivity)
    camera.rotate_x(-relative_motion.y * sensitivity)
    camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)

func _unhandled_input(event):
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _rotate_camera(event.relative, mouse_sensitivity)

    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        if event.keycode == KEY_R:
            weapon.reload()

    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            weapon.fire(raycast)

func _physics_process(delta):
    var keyboard_input = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    )
    var input_dir: Vector2 = keyboard_input + mobile_move
    input_dir = input_dir.limit_length(1.0)

    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0

    move_and_slide()
