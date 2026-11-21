extends CharacterBody3D

@export var move_speed: float = 7.0
@export var mouse_sensitivity: float = 0.002
@export var touch_sensitivity: float = 0.004
@export var max_health: float = 100.0

var health: float = 100.0
var gravity: float = 20.0
var mobile_move := Vector2.ZERO
var joystick_touch_id := -1
var look_touch_id := -1
var joystick_center := Vector2.ZERO
var joystick_home_center := Vector2.ZERO
var joystick_radius: float = 58.0

@onready var camera = $Camera3D
@onready var weapon = $Camera3D/Weapon
@onready var raycast = $Camera3D/RayCast3D

var touch_overlay: Control
var joystick_base: Panel
var joystick_knob: Panel
var health_label: Label
var ammo_label: Label
var fire_button: Button
var reload_button: Button
var fire_button_rect := Rect2()
var reload_button_rect := Rect2()

func _ready():
    add_to_group("player")
    health = max_health
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _create_mobile_controls()
    _create_hud()

func _create_mobile_controls():
    var canvas := CanvasLayer.new()
    canvas.name = "MobileControlsLayer"
    add_child(canvas)

    touch_overlay = Control.new()
    touch_overlay.name = "MobileControls"
    touch_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    touch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
    base_style.set_border_width_all(2)
    base_style.border_color = Color(0.85, 0.9, 0.95, 0.65)
    joystick_base.add_theme_stylebox_override("panel", base_style)
    touch_overlay.add_child(joystick_base)

    joystick_center = joystick_base.position + joystick_base.size / 2.0
    joystick_home_center = joystick_center
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

func _create_hud():
    var canvas := get_node("MobileControlsLayer")
    var screen_size := get_viewport().get_visible_rect().size

    health_label = Label.new()
    health_label.name = "HealthLabel"
    health_label.position = Vector2(24, 20)
    health_label.add_theme_font_size_override("font_size", 25)
    health_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
    canvas.add_child(health_label)

    ammo_label = Label.new()
    ammo_label.name = "AmmoLabel"
    ammo_label.position = Vector2(24, 54)
    ammo_label.add_theme_font_size_override("font_size", 23)
    ammo_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.65))
    canvas.add_child(ammo_label)

    fire_button = Button.new()
    fire_button.name = "FireButton"
    fire_button.text = "FIRE"
    fire_button.position = Vector2(screen_size.x - 142, screen_size.y - 190)
    fire_button.size = Vector2(112, 76)
    fire_button.add_theme_font_size_override("font_size", 22)
    fire_button.modulate = Color(1.0, 0.72, 0.62, 0.95)
    fire_button.pressed.connect(_on_fire_pressed)
    canvas.add_child(fire_button)

    reload_button = Button.new()
    reload_button.name = "ReloadButton"
    reload_button.text = "RELOAD"
    reload_button.position = Vector2(screen_size.x - 142, screen_size.y - 98)
    reload_button.size = Vector2(112, 58)
    reload_button.add_theme_font_size_override("font_size", 17)
    reload_button.pressed.connect(_on_reload_pressed)
    canvas.add_child(reload_button)

    fire_button_rect = Rect2(fire_button.position, fire_button.size)
    reload_button_rect = Rect2(reload_button.position, reload_button.size)

func _on_fire_pressed():
    weapon.fire(raycast)

func _on_reload_pressed():
    weapon.reload()

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            if fire_button_rect.has_point(event.position) or reload_button_rect.has_point(event.position):
                return

            var screen_size := get_viewport().get_visible_rect().size
            if event.position.x < screen_size.x * 0.5 and event.position.y > screen_size.y * 0.35 and joystick_touch_id == -1:
                joystick_touch_id = event.index
                joystick_center = event.position
                joystick_base.position = joystick_center - joystick_base.size / 2.0
                _update_joystick(event.position)
            elif event.position.x >= screen_size.x * 0.5 and look_touch_id == -1:
                look_touch_id = event.index
        else:
            if event.index == joystick_touch_id:
                joystick_touch_id = -1
                mobile_move = Vector2.ZERO
                joystick_center = joystick_home_center
                joystick_base.position = joystick_center - joystick_base.size / 2.0
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

func _process(_delta):
    if is_instance_valid(health_label):
        health_label.text = "HEALTH: %d" % int(health)
    if is_instance_valid(ammo_label) and is_instance_valid(weapon):
        ammo_label.text = "AMMO: %d / %d" % [weapon.ammo_in_magazine, weapon.reserve_ammo]
    if is_instance_valid(fire_button):
        fire_button.disabled = weapon.reloading
    if is_instance_valid(reload_button):
        reload_button.disabled = weapon.reloading or weapon.ammo_in_magazine == weapon.magazine_size or weapon.reserve_ammo <= 0

func _physics_process(delta):
    var keyboard_input = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    )
    var input_dir: Vector2 = (keyboard_input + mobile_move).limit_length(1.0)
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    move_and_slide()

func take_damage(amount: float):
    health = max(health - amount, 0.0)
    print("Player health: ", health, "/", max_health)
    if health <= 0.0:
        _die()

func _die():
    print("You have been eliminated!")
    set_physics_process(false)
    set_process_input(false)
    set_process_unhandled_input(false)
