extends CharacterBody3D

@export var move_speed: float = 7.0
@export var mouse_sensitivity: float = 0.002
@export var touch_sensitivity: float = 0.004
@export var max_health: float = 100.0

var health: float = 100.0
var armor: float = 0.0
var staging_panel: PanelContainer
var staging_status_label: Label
var staging_credits_label: Label
var staging_weapon_select: OptionButton
var staging_armor_button: Button
var gravity: float = 20.0
@onready var controller: TacticalPlayerController = $Controller
var mobile_move := Vector2.ZERO
var joystick_touch_id := -1
var look_touch_id := -1
var joystick_center := Vector2.ZERO
var joystick_home_center := Vector2.ZERO
var look_joystick_center := Vector2.ZERO
var look_joystick_home_center := Vector2.ZERO
var joystick_radius: float = 58.0
var look_joystick_radius: float = 58.0

@onready var camera = $Camera3D
@onready var weapon = $Camera3D/Weapon
@onready var raycast = $Camera3D/RayCast3D

var touch_overlay: Control
var joystick_base: Panel
var joystick_knob: Panel
var look_joystick_base: Panel
var look_joystick_knob: Panel
var health_label: Label
var armor_label: Label
var health_bar: ProgressBar
var armor_bar: ProgressBar
var ammo_label: Label
var fire_button: Button
var reload_button: Button
var fire_button_rect := Rect2()
var reload_button_rect := Rect2()
var mobile_sprint: bool = false
var mobile_aiming: bool = false
var mouse_aiming: bool = false
var controller_firing: bool = false
var last_gamepad_connected: bool = false
var controller_hint_label: Label
var hit_marker_label: Label
var hit_marker_timer: float = 0.0
var hit_marker_kill: bool = false
@export var controller_look_speed: float = 2.4
var mobile_crouch: bool = false
var mobile_prone: bool = false
var mobile_jump_requested: bool = false
var jump_key_was_down: bool = false
var body_collision: CollisionShape3D
var sprint_button: Button
var crouch_button: Button
var prone_button: Button
var jump_button: Button
var aim_button: Button
var aiming: bool = false
var crosshair_label: Label
var weapon_label: Label
var weapon_prev_button: Button
var weapon_next_button: Button
var weapon_select: OptionButton
var attachment_toggle: Button
var attachment_panel: PanelContainer
var attachment_selectors: Dictionary = {}

func _ready():
    add_to_group("player")
    health = max_health
    GameSession.restore_player_state(self)
    body_collision = $CollisionShape3D
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _create_mobile_controls()
    _create_hud()
    _layout_mobile_controls()
    get_viewport().size_changed.connect(_layout_mobile_controls)
    if weapon.has_signal("hit_confirmed"):
        weapon.hit_confirmed.connect(_on_hit_confirmed)
    _refresh_control_presentation()
    _create_staging_ui()

func _exit_tree() -> void:
    GameSession.store_player_state(self)

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

    look_joystick_base = Panel.new()
    look_joystick_base.name = "LookJoystickBase"
    look_joystick_base.position = Vector2(screen_size.x - 176, screen_size.y - 184)
    look_joystick_base.size = Vector2(144, 144)
    look_joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    look_joystick_base.add_theme_stylebox_override("panel", base_style)
    touch_overlay.add_child(look_joystick_base)
    look_joystick_home_center = look_joystick_base.position + look_joystick_base.size / 2.0
    look_joystick_center = look_joystick_home_center

    look_joystick_knob = Panel.new()
    look_joystick_knob.name = "LookJoystickKnob"
    look_joystick_knob.position = look_joystick_center - Vector2(29, 29)
    look_joystick_knob.size = Vector2(58, 58)
    look_joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    look_joystick_knob.add_theme_stylebox_override("panel", knob_style)
    touch_overlay.add_child(look_joystick_knob)

func _create_hud():
    var canvas := get_node("MobileControlsLayer")
    var screen_size := get_viewport().get_visible_rect().size

    health_label = Label.new()
    health_label.name = "HealthLabel"
    health_label.position = Vector2(24, 18)
    health_label.add_theme_font_size_override("font_size", 18)
    health_label.add_theme_color_override("font_color", Color(0.88, 0.96, 0.88))
    canvas.add_child(health_label)

    health_bar = ProgressBar.new()
    health_bar.name = "HealthBar"
    health_bar.position = Vector2(24, 48)
    health_bar.size = Vector2(190, 13)
    health_bar.max_value = max_health
    health_bar.show_percentage = false
    var health_fill := StyleBoxFlat.new()
    health_fill.bg_color = Color(0.30, 0.72, 0.38, 1.0)
    health_bar.add_theme_stylebox_override("fill", health_fill)
    var bar_bg := StyleBoxFlat.new()
    bar_bg.bg_color = Color(0.05, 0.08, 0.07, 0.82)
    bar_bg.set_border_width_all(1)
    bar_bg.border_color = Color(0.62, 0.70, 0.62, 0.7)
    health_bar.add_theme_stylebox_override("background", bar_bg)
    canvas.add_child(health_bar)

    armor_label = Label.new()
    armor_label.name = "ArmorLabel"
    armor_label.position = Vector2(24, 65)
    armor_label.add_theme_font_size_override("font_size", 15)
    armor_label.add_theme_color_override("font_color", Color(0.68, 0.82, 0.96))
    canvas.add_child(armor_label)

    armor_bar = ProgressBar.new()
    armor_bar.name = "ArmorBar"
    armor_bar.position = Vector2(24, 87)
    armor_bar.size = Vector2(190, 9)
    armor_bar.max_value = 100.0
    armor_bar.show_percentage = false
    var armor_fill := StyleBoxFlat.new()
    armor_fill.bg_color = Color(0.28, 0.56, 0.82, 1.0)
    armor_bar.add_theme_stylebox_override("fill", armor_fill)
    armor_bar.add_theme_stylebox_override("background", bar_bg)
    canvas.add_child(armor_bar)

    ammo_label = Label.new()
    ammo_label.name = "AmmoLabel"
    ammo_label.position = Vector2(screen_size.x - 245, screen_size.y - 86)
    ammo_label.size = Vector2(220, 58)
    ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    ammo_label.add_theme_font_size_override("font_size", 26)
    ammo_label.add_theme_color_override("font_color", Color(0.96, 0.91, 0.72))
    canvas.add_child(ammo_label)

    fire_button = Button.new()
    fire_button.name = "FireButton"
    fire_button.text = "FIRE"
    fire_button.position = Vector2(screen_size.x - 142, screen_size.y - 190)
    fire_button.size = Vector2(112, 76)
    fire_button.add_theme_font_size_override("font_size", 22)
    fire_button.modulate = Color(1.0, 0.72, 0.62, 0.95)
    fire_button.button_down.connect(_on_fire_pressed)
    fire_button.button_up.connect(_on_fire_released)
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

    sprint_button = Button.new()
    sprint_button.name = "SprintButton"
    sprint_button.text = "SPRINT"
    sprint_button.position = Vector2(screen_size.x - 270, screen_size.y - 190)
    sprint_button.size = Vector2(112, 64)
    sprint_button.toggle_mode = true
    sprint_button.add_theme_font_size_override("font_size", 17)
    sprint_button.toggled.connect(_on_sprint_toggled)
    canvas.add_child(sprint_button)

    crouch_button = Button.new()
    crouch_button.name = "CrouchButton"
    crouch_button.text = "CROUCH"
    crouch_button.position = Vector2(screen_size.x - 270, screen_size.y - 112)
    crouch_button.size = Vector2(112, 58)
    crouch_button.toggle_mode = true
    crouch_button.add_theme_font_size_override("font_size", 17)
    crouch_button.toggled.connect(_on_crouch_toggled)
    canvas.add_child(crouch_button)

    jump_button = Button.new()
    jump_button.name = "JumpButton"
    jump_button.text = "JUMP"
    jump_button.position = Vector2(screen_size.x - 142, screen_size.y - 282)
    jump_button.size = Vector2(112, 68)
    jump_button.add_theme_font_size_override("font_size", 19)
    jump_button.pressed.connect(_on_jump_pressed)
    canvas.add_child(jump_button)

    prone_button = Button.new()
    prone_button.name = "ProneButton"
    prone_button.text = "PRONE"
    prone_button.position = Vector2(screen_size.x - 400, screen_size.y - 112)
    prone_button.size = Vector2(112, 58)
    prone_button.toggle_mode = true
    prone_button.add_theme_font_size_override("font_size", 17)
    prone_button.toggled.connect(_on_prone_toggled)
    canvas.add_child(prone_button)

    aim_button = Button.new()
    aim_button.name = "AimButton"
    aim_button.text = "AIM"
    aim_button.position = Vector2(screen_size.x - 142, screen_size.y - 370)
    aim_button.size = Vector2(112, 64)
    aim_button.toggle_mode = true
    aim_button.add_theme_font_size_override("font_size", 19)
    aim_button.toggled.connect(_on_aim_toggled)
    canvas.add_child(aim_button)

    weapon_label = Label.new()
    weapon_label.name = "WeaponLabel"
    weapon_label.position = Vector2(screen_size.x - 300, 24)
    weapon_label.size = Vector2(280, 56)
    weapon_label.add_theme_font_size_override("font_size", 17)
    weapon_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.82))
    weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    canvas.add_child(weapon_label)

    weapon_prev_button = Button.new()
    weapon_prev_button.name = "WeaponPrevious"
    weapon_prev_button.text = "PREV"
    weapon_prev_button.position = Vector2(screen_size.x - 400, screen_size.y - 72)
    weapon_prev_button.size = Vector2(82, 50)
    weapon_prev_button.add_theme_font_size_override("font_size", 15)
    weapon_prev_button.pressed.connect(_on_previous_weapon)
    canvas.add_child(weapon_prev_button)

    weapon_next_button = Button.new()
    weapon_next_button.name = "WeaponNext"
    weapon_next_button.text = "NEXT"
    weapon_next_button.position = Vector2(screen_size.x - 308, screen_size.y - 72)
    weapon_next_button.size = Vector2(82, 50)
    weapon_next_button.add_theme_font_size_override("font_size", 15)
    weapon_next_button.pressed.connect(_on_next_weapon)
    canvas.add_child(weapon_next_button)

    weapon.weapon_changed.connect(_on_weapon_changed)

    crosshair_label = Label.new()
    crosshair_label.name = "Crosshair"
    crosshair_label.text = "+"
    crosshair_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    crosshair_label.position = Vector2(-8, -17)
    crosshair_label.add_theme_font_size_override("font_size", 30)
    crosshair_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
    canvas.add_child(crosshair_label)

    hit_marker_label = Label.new()
    hit_marker_label.name = "HitMarker"
    hit_marker_label.text = "×"
    hit_marker_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    hit_marker_label.position = Vector2(-13, -23)
    hit_marker_label.size = Vector2(26, 30)
    hit_marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hit_marker_label.add_theme_font_size_override("font_size", 30)
    hit_marker_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72, 1.0))
    hit_marker_label.visible = false
    canvas.add_child(hit_marker_label)

    controller_hint_label = Label.new()
    controller_hint_label.name = "ControllerHint"
    controller_hint_label.position = Vector2(0, screen_size.y - 38)
    controller_hint_label.size = Vector2(screen_size.x, 30)
    controller_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    controller_hint_label.add_theme_font_size_override("font_size", 15)
    controller_hint_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.82, 0.9))
    canvas.add_child(controller_hint_label)


func _layout_mobile_controls() -> void:
    if not is_instance_valid(touch_overlay):
        return
    var screen_size := get_viewport().get_visible_rect().size
    var scale_factor := clampf(minf(screen_size.x / 844.0, screen_size.y / 390.0), 0.72, 1.0)
    var edge := 18.0 * scale_factor
    var stick_size := 136.0 * scale_factor
    var knob_size := 56.0 * scale_factor
    var stick_y := screen_size.y - stick_size - 22.0 * scale_factor

    joystick_base.size = Vector2.ONE * stick_size
    joystick_base.position = Vector2(edge, stick_y)
    joystick_center = joystick_base.position + joystick_base.size * 0.5
    joystick_home_center = joystick_center
    joystick_knob.size = Vector2.ONE * knob_size
    joystick_knob.position = joystick_center - joystick_knob.size * 0.5
    joystick_radius = stick_size * 0.40

    look_joystick_base.size = Vector2.ONE * stick_size
    look_joystick_base.position = Vector2(screen_size.x - stick_size - 246.0 * scale_factor, stick_y)
    look_joystick_home_center = look_joystick_base.position + look_joystick_base.size * 0.5
    look_joystick_center = look_joystick_home_center
    look_joystick_knob.size = Vector2.ONE * knob_size
    look_joystick_knob.position = look_joystick_center - look_joystick_knob.size * 0.5
    look_joystick_radius = stick_size * 0.40

    var action_x := screen_size.x - 104.0 * scale_factor
    var action_w := 88.0 * scale_factor
    var action_h := 56.0 * scale_factor
    aim_button.position = Vector2(action_x, screen_size.y - 4.0 * action_h - 28.0 * scale_factor)
    aim_button.size = Vector2(action_w, action_h)
    jump_button.position = Vector2(action_x, screen_size.y - 3.0 * action_h - 20.0 * scale_factor)
    jump_button.size = Vector2(action_w, action_h)
    fire_button.position = Vector2(action_x, screen_size.y - 2.0 * action_h - 12.0 * scale_factor)
    fire_button.size = Vector2(action_w, action_h)
    reload_button.position = Vector2(action_x, screen_size.y - action_h - 8.0 * scale_factor)
    reload_button.size = Vector2(action_w, action_h * 0.78)

    var utility_x := screen_size.x - 374.0 * scale_factor
    var utility_w := 94.0 * scale_factor
    var utility_h := 44.0 * scale_factor
    sprint_button.position = Vector2(utility_x, screen_size.y - 2.0 * utility_h - 20.0 * scale_factor)
    sprint_button.size = Vector2(utility_w, utility_h)
    crouch_button.position = Vector2(utility_x + utility_w + 8.0 * scale_factor, screen_size.y - 2.0 * utility_h - 20.0 * scale_factor)
    crouch_button.size = Vector2(utility_w, utility_h)
    prone_button.position = Vector2(utility_x, screen_size.y - utility_h - 12.0 * scale_factor)
    prone_button.size = Vector2(utility_w, utility_h)
    weapon_prev_button.position = Vector2(utility_x + utility_w + 8.0 * scale_factor, screen_size.y - utility_h - 12.0 * scale_factor)
    weapon_prev_button.size = Vector2(utility_w * 0.52, utility_h)
    weapon_next_button.position = Vector2(weapon_prev_button.position.x + weapon_prev_button.size.x + 6.0 * scale_factor, screen_size.y - utility_h - 12.0 * scale_factor)
    weapon_next_button.size = Vector2(utility_w * 0.52, utility_h)

    ammo_label.position = Vector2(screen_size.x - 250.0 * scale_factor, screen_size.y - 72.0 * scale_factor)
    ammo_label.size = Vector2(138.0 * scale_factor, 56.0 * scale_factor)
    ammo_label.add_theme_font_size_override("font_size", int(22.0 * scale_factor))
    weapon_label.position = Vector2(screen_size.x - 300.0 * scale_factor, 20.0 * scale_factor)
    weapon_label.size = Vector2(280.0 * scale_factor, 52.0 * scale_factor)
    weapon_label.add_theme_font_size_override("font_size", int(15.0 * scale_factor))
    health_label.position = Vector2(20.0 * scale_factor, 16.0 * scale_factor)
    health_bar.position = Vector2(20.0 * scale_factor, 44.0 * scale_factor)
    health_bar.size = Vector2(176.0 * scale_factor, 12.0 * scale_factor)
    armor_label.position = Vector2(20.0 * scale_factor, 62.0 * scale_factor)
    armor_bar.position = Vector2(20.0 * scale_factor, 84.0 * scale_factor)
    armor_bar.size = Vector2(176.0 * scale_factor, 8.0 * scale_factor)
    controller_hint_label.position = Vector2(0.0, screen_size.y - 30.0 * scale_factor)
    controller_hint_label.size = Vector2(screen_size.x, 24.0 * scale_factor)
    fire_button_rect = Rect2(fire_button.position, fire_button.size)
    reload_button_rect = Rect2(reload_button.position, reload_button.size)


func _create_staging_ui() -> void:
    var canvas := get_node("MobileControlsLayer") as CanvasLayer
    var overlay := ColorRect.new()
    overlay.name = "StagingBackdrop"
    overlay.color = Color(0.025, 0.035, 0.04, 0.96)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    canvas.add_child(overlay)

    staging_panel = PanelContainer.new()
    staging_panel.name = "PreBattleStaging"
    var screen_size := get_viewport().get_visible_rect().size
    var panel_size := Vector2(minf(screen_size.x - 24.0, 620.0), minf(screen_size.y - 24.0, 520.0))
    staging_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    staging_panel.position = -panel_size * 0.5
    staging_panel.size = panel_size
    staging_panel.custom_minimum_size = panel_size
    staging_panel.process_mode = Node.PROCESS_MODE_ALWAYS
    overlay.add_child(staging_panel)

    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.custom_minimum_size = Vector2(0.0, panel_size.y - 20.0)
    staging_panel.add_child(scroll)

    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation", 8)
    scroll.add_child(column)

    var title := Label.new()
    title.text = "HUNGER FOR WAR  |  PRE-DEPLOYMENT"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 23)
    column.add_child(title)

    var briefing := Label.new()
    briefing.text = "FIELD STAGING  •  SELECT YOUR WEAPON AND EQUIPMENT"
    briefing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    briefing.add_theme_font_size_override("font_size", 14)
    column.add_child(briefing)

    staging_credits_label = Label.new()
    staging_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    staging_credits_label.add_theme_font_size_override("font_size", 19)
    column.add_child(staging_credits_label)

    staging_weapon_select = OptionButton.new()
    staging_weapon_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    staging_weapon_select.add_theme_font_size_override("font_size", 16)
    for item in weapon.weapon_list:
        staging_weapon_select.add_item("%s  |  %s" % [item.get("name", "Weapon"), item.get("class", "Class")])
        staging_weapon_select.set_item_metadata(staging_weapon_select.get_item_count() - 1, item.get("id", ""))
    var selected := 0
    for i in range(staging_weapon_select.item_count):
        if str(staging_weapon_select.get_item_metadata(i)) == weapon.current_weapon_id:
            selected = i
            break
    staging_weapon_select.select(selected)
    column.add_child(staging_weapon_select)

    var buy_weapon := Button.new()
    buy_weapon.text = "PURCHASE / EQUIP SELECTED WEAPON"
    buy_weapon.custom_minimum_size.y = 48
    buy_weapon.pressed.connect(_purchase_staging_weapon)
    column.add_child(buy_weapon)

    staging_armor_button = Button.new()
    staging_armor_button.text = "BUY BODY ARMOR  •  500 CREDITS"
    staging_armor_button.custom_minimum_size.y = 44
    staging_armor_button.pressed.connect(_purchase_staging_armor)
    column.add_child(staging_armor_button)

    var ammo_button := Button.new()
    ammo_button.text = "BUY AMMUNITION  •  250 CREDITS"
    ammo_button.custom_minimum_size.y = 44
    ammo_button.pressed.connect(_purchase_staging_ammo)
    column.add_child(ammo_button)

    staging_status_label = Label.new()
    staging_status_label.text = "Choose your loadout. The battlefield is paused until deployment."
    staging_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    staging_status_label.custom_minimum_size.y = 48
    column.add_child(staging_status_label)

    var deploy := Button.new()
    deploy.text = "DEPLOY TO BATTLE"
    deploy.custom_minimum_size.y = 58
    deploy.add_theme_font_size_override("font_size", 21)
    deploy.pressed.connect(_deploy_from_staging)
    column.add_child(deploy)

    _refresh_staging_ui()
    get_tree().paused = true

func _refresh_staging_ui() -> void:
    if is_instance_valid(staging_credits_label):
        staging_credits_label.text = "AVAILABLE CREDITS: %d" % GameSession.credits
    if is_instance_valid(staging_armor_button):
        staging_armor_button.text = "BODY ARMOR  •  EQUIPPED" if armor > 0.0 else "BUY BODY ARMOR  •  500 CREDITS"

func _purchase_staging_weapon() -> void:
    if not is_instance_valid(staging_weapon_select):
        return
    var weapon_id := str(staging_weapon_select.get_item_metadata(staging_weapon_select.selected))
    var selected_item: Dictionary = {}
    for entry in weapon.weapon_list:
        if str(entry.get("id", "")) == weapon_id:
            selected_item = entry
            break
    if selected_item.is_empty():
        return
    var weapon_class := str(selected_item.get("class", "")).to_lower()
    var price := 900
    if weapon_class.contains("sniper") or weapon_class.contains("machine gun"):
        price = 1500
    elif weapon_class.contains("launcher"):
        price = 1800
    elif weapon_class.contains("pistol") or weapon_class.contains("smg"):
        price = 600
    if weapon_id != weapon.current_weapon_id:
        if GameSession.credits < price:
            staging_status_label.text = "Not enough credits. This weapon costs %d." % price
            return
        GameSession.spend_credits(price)
    weapon.equip_weapon_by_id(weapon_id)
    staging_status_label.text = "%s equipped." % weapon.current_weapon_name
    _refresh_staging_ui()

func _purchase_staging_armor() -> void:
    if armor > 0.0:
        staging_status_label.text = "Body armor is already equipped."
        return
    if GameSession.credits < 500:
        staging_status_label.text = "Not enough credits for body armor."
        return
    GameSession.spend_credits(500)
    armor = 50.0
    staging_status_label.text = "Body armor equipped: 50 protection."
    _refresh_staging_ui()

func _purchase_staging_ammo() -> void:
    if GameSession.credits < 250:
        staging_status_label.text = "Not enough credits for ammunition."
        return
    GameSession.spend_credits(250)
    weapon.reserve_ammo += 60
    staging_status_label.text = "Ammunition purchased: +60 rounds."
    _refresh_staging_ui()

func _deploy_from_staging() -> void:
    if is_instance_valid(staging_panel):
        staging_panel.get_parent().queue_free()
    get_tree().paused = false

func _refresh_control_presentation():
    last_gamepad_connected = Input.get_connected_joypads().size() > 0
    var show_touch_controls := DisplayServer.is_touchscreen_available() and not last_gamepad_connected
    var touch_controls = [touch_overlay, fire_button, reload_button, sprint_button, crouch_button, prone_button, jump_button, aim_button, weapon_prev_button, weapon_next_button]
    for control in touch_controls:
        if is_instance_valid(control):
            control.visible = show_touch_controls
    if is_instance_valid(controller_hint_label):
        controller_hint_label.visible = last_gamepad_connected
        controller_hint_label.text = "LEFT STICK MOVE   RIGHT STICK LOOK   LT AIM   RT FIRE   FACE BUTTONS   LB/RB WEAPONS"

func _toggle_attachment_panel():
    attachment_panel.visible = not attachment_panel.visible
    if attachment_panel.visible:
        _refresh_attachment_selectors()

func _refresh_attachment_selectors():
    if not is_instance_valid(weapon):
        return
    for slot in attachment_selectors.keys():
        var selector: OptionButton = attachment_selectors[slot]
        selector.clear()
        var options: Array = weapon.get_attachment_options(str(slot))
        var selected_index := 0
        for i in range(options.size()):
            var option: Dictionary = options[i]
            selector.add_item(str(option.get("name", "Default")))
            selector.set_item_metadata(i, str(option.get("id", "none")))
            if str(option.get("id", "")) == str(weapon.attachments.get(slot, "none")):
                selected_index = i
        if selector.item_count > 0:
            selector.select(selected_index)

func _on_attachment_selected(index: int, slot: String):
    var selector: OptionButton = attachment_selectors[slot]
    weapon.set_attachment(slot, str(selector.get_item_metadata(index)))
    _refresh_attachment_selectors()

func _on_hit_confirmed(killed: bool):
    hit_marker_kill = killed
    hit_marker_timer = 0.48 if killed else 0.20
    if is_instance_valid(hit_marker_label):
        hit_marker_label.text = "✕" if killed else "×"
        hit_marker_label.add_theme_color_override("font_color", Color(1.0, 0.36, 0.24, 1.0) if killed else Color(1.0, 0.94, 0.76, 1.0))
        hit_marker_label.add_theme_font_size_override("font_size", 34 if killed else 30)
        hit_marker_label.visible = true
        hit_marker_label.modulate.a = 1.0

func _on_sprint_toggled(enabled: bool):
    mobile_sprint = enabled

func _on_crouch_toggled(enabled: bool):
    mobile_crouch = enabled
    if enabled:
        mobile_prone = false
        if is_instance_valid(prone_button):
            prone_button.button_pressed = false

func _on_prone_toggled(enabled: bool):
    mobile_prone = enabled
    if enabled:
        mobile_crouch = false
        if is_instance_valid(crouch_button):
            crouch_button.button_pressed = false

func _on_jump_pressed():
    mobile_jump_requested = true

func _on_aim_toggled(enabled: bool):
    mobile_aiming = enabled

func _on_fire_pressed():
    weapon.start_firing()

func _on_fire_released():
    weapon.stop_firing()

func _on_previous_weapon():
    weapon.cycle_weapon(-1)

func _on_next_weapon():
    weapon.cycle_weapon(1)

func _on_weapon_selected(index: int):
    var selected_id = weapon_select.get_item_metadata(index)
    weapon.equip_weapon_by_id(str(selected_id))

func _on_weapon_changed(_weapon_name: String, _weapon_class: String):
    pass

func _on_reload_pressed():
    weapon.reload()

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            if _is_touch_ui(event.position):
                return

            var screen_size := get_viewport().get_visible_rect().size
            if event.position.x < screen_size.x * 0.5 and event.position.y > screen_size.y * 0.35 and joystick_touch_id == -1:
                joystick_touch_id = event.index
                joystick_center = event.position
                joystick_base.position = joystick_center - joystick_base.size / 2.0
                _update_joystick(event.position)
            elif event.position.x >= screen_size.x * 0.5 and look_touch_id == -1 and look_joystick_base.get_global_rect().has_point(event.position):
                look_touch_id = event.index
                _update_look_joystick(event.position)
        else:
            if event.index == joystick_touch_id:
                joystick_touch_id = -1
                mobile_move = Vector2.ZERO
                joystick_center = joystick_home_center
                joystick_base.position = joystick_center - joystick_base.size / 2.0
                joystick_knob.position = joystick_center - joystick_knob.size / 2.0
            if event.index == look_touch_id:
                look_touch_id = -1
                look_joystick_center = look_joystick_home_center
                look_joystick_knob.position = look_joystick_center - look_joystick_knob.size / 2.0

    elif event is InputEventScreenDrag:
        if event.index == joystick_touch_id:
            _update_joystick(event.position)
        elif event.index == look_touch_id:
            _update_look_joystick(event.position)
            _rotate_camera(event.relative, touch_sensitivity)

func _is_touch_ui(touch_position: Vector2) -> bool:
    var controls = [fire_button, reload_button, sprint_button, crouch_button, prone_button, jump_button, aim_button, weapon_prev_button, weapon_next_button]
    for control in controls:
        if is_instance_valid(control) and Rect2(control.position, control.size).has_point(touch_position):
            return true
    return false

func _update_joystick(touch_position: Vector2):
    var offset: Vector2 = touch_position - joystick_center
    if offset.length() > joystick_radius:
        offset = offset.normalized() * joystick_radius
    mobile_move = offset / joystick_radius
    joystick_knob.position = joystick_center + offset - joystick_knob.size / 2.0

func _update_look_joystick(touch_position: Vector2) -> void:
    var offset: Vector2 = touch_position - look_joystick_center
    if offset.length() > look_joystick_radius:
        offset = offset.normalized() * look_joystick_radius
    look_joystick_knob.position = look_joystick_center + offset - look_joystick_knob.size / 2.0

func _rotate_camera(relative_motion: Vector2, sensitivity: float):
    rotate_y(-relative_motion.x * sensitivity)
    camera.feed_look_motion(relative_motion * sensitivity)
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
        if event.keycode == KEY_Q:
            weapon.cycle_weapon(-1)
        if event.keycode == KEY_E:
            weapon.cycle_weapon(1)

    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                weapon.start_firing()
            else:
                weapon.stop_firing()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            mouse_aiming = event.pressed

func _process(delta):
    if hit_marker_timer > 0.0:
        hit_marker_timer = maxf(hit_marker_timer - delta, 0.0)
        if is_instance_valid(hit_marker_label):
            hit_marker_label.visible = hit_marker_timer > 0.0
            hit_marker_label.modulate.a = clampf(hit_marker_timer / (0.48 if hit_marker_kill else 0.20), 0.0, 1.0)
    var gamepad_connected := Input.get_connected_joypads().size() > 0
    if gamepad_connected != last_gamepad_connected:
        _refresh_control_presentation()
    var look_input := Vector2.ZERO
    for device_id in Input.get_connected_joypads():
        var stick := Vector2(
            Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X),
            Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
        )
        if stick.length() > 0.18:
            var strength := clampf((stick.length() - 0.18) / 0.82, 0.0, 1.0)
            look_input = stick.normalized() * pow(strength, 1.25)
            break
    if look_input.length() > 0.01:
        _rotate_camera(look_input * controller_look_speed * (0.55 if aiming else 1.0) * delta, 1.0)
    var wants_aim := mobile_aiming or mouse_aiming or Input.is_action_pressed("aim")
    if wants_aim != aiming:
        aiming = wants_aim
        weapon.set_aiming(aiming)
    var wants_fire := false
    for device_id in Input.get_connected_joypads():
        if Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > 0.65:
            wants_fire = true
            break
    if wants_fire != controller_firing:
        controller_firing = wants_fire
        if controller_firing:
            weapon.start_firing()
        else:
            weapon.stop_firing()
    if Input.is_action_just_pressed("reload"):
        weapon.reload()
    if Input.is_action_just_pressed("weapon_previous"):
        weapon.cycle_weapon(-1)
    if Input.is_action_just_pressed("weapon_next"):
        weapon.cycle_weapon(1)
    if Input.is_action_just_pressed("jump") and is_on_floor():
        mobile_jump_requested = true

    if is_instance_valid(health_label):
        health_label.text = "VITALS  %03d%%" % int(health)
    if is_instance_valid(health_bar):
        health_bar.value = clampf(health, 0.0, max_health)
    if is_instance_valid(armor_label):
        armor_label.text = "ARMOR  %03d%%" % int(armor)
    if is_instance_valid(armor_bar):
        armor_bar.value = clampf(armor, 0.0, 100.0)
    if is_instance_valid(ammo_label) and is_instance_valid(weapon):
        ammo_label.text = "%02d  /  %03d\n%s" % [weapon.ammo_in_magazine, weapon.reserve_ammo, "RELOADING" if weapon.reloading else weapon.fire_mode]
    if is_instance_valid(weapon_label) and is_instance_valid(weapon):
        weapon_label.text = "%s\\n%s | %s" % [weapon.current_weapon_name, weapon.caliber, weapon.fire_mode]
    if is_instance_valid(fire_button):
        fire_button.disabled = weapon.reloading
    if is_instance_valid(reload_button):
        reload_button.disabled = weapon.reloading or weapon.ammo_in_magazine == weapon.magazine_size or weapon.reserve_ammo <= 0
    if is_instance_valid(camera):
        camera.set_aiming(aiming)
    if is_instance_valid(crosshair_label):
        crosshair_label.visible = not aiming

func _physics_process(delta: float) -> void:
    var input_dir: Vector2 = (Input.get_vector("move_left", "move_right", "move_forward", "move_back") + mobile_move).limit_length(1.0)
    var sprinting := Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("sprint") or mobile_sprint
    var prone := Input.is_key_pressed(KEY_Z) or mobile_prone
    var crouching := Input.is_key_pressed(KEY_CTRL) or Input.is_action_pressed("crouch") or mobile_crouch
    var jump_key_down := Input.is_key_pressed(KEY_SPACE) or Input.is_action_pressed("jump")
    var jump_requested := (jump_key_down and not jump_key_was_down) or mobile_jump_requested
    jump_key_was_down = jump_key_down
    mobile_jump_requested = false

    controller.physics_step(delta, input_dir, sprinting, crouching, prone, jump_requested)

    if is_instance_valid(sprint_button):
        sprint_button.text = "SPRINT ON" if mobile_sprint else "SPRINT"
    if is_instance_valid(crouch_button):
        crouch_button.text = "STAND" if mobile_crouch else "CROUCH"
    if is_instance_valid(prone_button):
        prone_button.text = "GET UP" if mobile_prone else "PRONE"

func take_damage(amount: float):
    var remaining_damage := amount
    if armor > 0.0:
        var absorbed := minf(armor, remaining_damage * 0.65)
        armor -= absorbed
        remaining_damage -= absorbed
    health = maxf(health - remaining_damage, 0.0)
    print("Player health: ", health, "/", max_health)
    if health <= 0.0:
        _die()

func _die():
    print("You have been eliminated!")
    set_physics_process(false)
    set_process_input(false)
    set_process_unhandled_input(false)
