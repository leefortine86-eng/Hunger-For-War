extends Node3D

const WEAPON_CATALOG = preload("res://scripts/weapon_catalog.gd")

@export var default_weapon_id: String = "m4"

var weapon_list: Array = []
var current_index: int = 0
var current_weapon: Dictionary = {}
var current_weapon_id: String = ""
var current_weapon_name: String = "M4"
var damage: float = 27.0
var fire_rate: float = 0.075
var magazine_size: int = 30
var reserve_ammo: int = 120
var ammo_in_magazine: int = 30
var reload_time: float = 2.0
var effective_range: float = 400.0
var fire_mode: String = "AUTO"
var weapon_class: String = "Assault Rifle"
var caliber: String = "5.56x45mm"
var can_fire: bool = true
var reloading: bool = false
var aiming: bool = false
var trigger_held: bool = false
var recoil_amount: float = 0.0
var muzzle_timer: float = 0.0
var reload_remaining: float = 0.0
var fire_cooldown: float = 0.0
var bob_time: float = 0.0
var reload_visual: float = 0.0
var weapon_home_position := Vector3(0.28, -0.25, -0.55)
var weapon_aim_position := Vector3(0.0, -0.16, -0.42)
var muzzle_light: OmniLight3D
var weapon_model: Node3D

signal weapon_changed(weapon_name: String, weapon_class: String)

func _ready():
    weapon_list = WEAPON_CATALOG.get_weapons()
    equip_weapon_by_id(default_weapon_id)

func get_weapon_count() -> int:
    return weapon_list.size()

func get_weapon_summary() -> String:
    return "%s | %s | %s" % [current_weapon_name, caliber, fire_mode]

func equip_weapon_by_id(weapon_id: String):
    for i in range(weapon_list.size()):
        if weapon_list[i].get("id", "") == weapon_id:
            current_index = i
            _apply_weapon_data(weapon_list[i])
            return
    if not weapon_list.is_empty():
        current_index = 0
        _apply_weapon_data(weapon_list[0])

func cycle_weapon(direction: int):
    if weapon_list.is_empty():
        return
    current_index = posmod(current_index + direction, weapon_list.size())
    _apply_weapon_data(weapon_list[current_index])

func _apply_weapon_data(data: Dictionary):
    current_weapon = data
    current_weapon_id = str(data.get("id", "m4"))
    current_weapon_name = str(data.get("name", "Rifle"))
    weapon_class = str(data.get("class", "Rifle"))
    caliber = str(data.get("caliber", "Unknown"))
    damage = float(data.get("damage", 25.0))
    var rpm := float(data.get("rpm", 600.0))
    fire_rate = 60.0 / maxf(rpm, 1.0)
    magazine_size = int(data.get("mag", 30))
    reserve_ammo = int(data.get("reserve", magazine_size * 4))
    ammo_in_magazine = magazine_size
    reload_time = float(data.get("reload", 2.0))
    effective_range = float(data.get("range", 300.0))
    fire_mode = str(data.get("mode", "SEMI"))
    reloading = false
    trigger_held = false
    reload_remaining = 0.0
    _build_weapon_model()
    weapon_changed.emit(current_weapon_name, weapon_class)
    print("Equipped: ", current_weapon_name, " | ", caliber, " | ", fire_mode)

func _material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = 0.58
    return material

func _add_box(part_name: String, size: Vector3, pos: Vector3, color: Color):
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := BoxMesh.new()
    mesh.size = size
    part.mesh = mesh
    part.position = pos
    part.material_override = _material(color)
    weapon_model.add_child(part)
    return part

func _build_weapon_model():
    if is_instance_valid(weapon_model):
        weapon_model.queue_free()
    weapon_model = Node3D.new()
    weapon_model.name = "WeaponModel_" + current_weapon_id
    add_child(weapon_model)

    var dark := Color(0.065, 0.075, 0.07)
    var metal := Color(0.19, 0.21, 0.19)
    var polymer := Color(0.12, 0.13, 0.11)
    var profile := str(current_weapon.get("profile", "rifle"))
    var receiver_length := 0.48
    var barrel_length := 0.32
    var body_width := 0.12
    var body_height := 0.13
    var magazine_size_visual := Vector3(0.085, 0.22, 0.12)

    match profile:
        "pistol":
            receiver_length = 0.28
            barrel_length = 0.16
            body_width = 0.10
            body_height = 0.12
            magazine_size_visual = Vector3(0.075, 0.15, 0.09)
        "smg":
            receiver_length = 0.38
            barrel_length = 0.22
            magazine_size_visual = Vector3(0.08, 0.24, 0.10)
        "sniper":
            receiver_length = 0.62
            barrel_length = 0.58
            magazine_size_visual = Vector3(0.09, 0.19, 0.13)
        "dmr":
            receiver_length = 0.55
            barrel_length = 0.45
        "lmg":
            receiver_length = 0.58
            barrel_length = 0.48
            magazine_size_visual = Vector3(0.14, 0.26, 0.18)
        "shotgun":
            receiver_length = 0.50
            barrel_length = 0.42
            magazine_size_visual = Vector3(0.07, 0.16, 0.09)
        "launcher":
            receiver_length = 0.30
            barrel_length = 0.72
            body_width = 0.17
            body_height = 0.17
            magazine_size_visual = Vector3(0.12, 0.12, 0.12)
        "bow":
            receiver_length = 0.18
            barrel_length = 0.35

    if profile == "pistol":
        _add_box("Slide", Vector3(body_width, body_height, receiver_length), Vector3(0, 0, -0.02), metal)
        _add_box("PistolGrip", Vector3(0.085, 0.20, 0.10), Vector3(0, -0.15, 0.10), polymer)
        _add_box("MagazineBase", magazine_size_visual, Vector3(0, -0.20, 0.04), dark)
    elif profile == "bow":
        _add_box("BowGrip", Vector3(0.08, 0.34, 0.08), Vector3(0, 0, 0), polymer)
        _add_box("UpperLimb", Vector3(0.04, 0.40, 0.05), Vector3(0, 0.30, 0), metal)
        _add_box("LowerLimb", Vector3(0.04, 0.40, 0.05), Vector3(0, -0.30, 0), metal)
        _add_box("Arrow", Vector3(0.025, 0.025, 0.72), Vector3(0, 0, -0.36), metal)
    elif profile == "launcher":
        _add_box("LauncherTube", Vector3(body_width, body_height, barrel_length + receiver_length), Vector3(0, 0, -0.30), dark)
        _add_box("LauncherSight", Vector3(0.10, 0.12, 0.16), Vector3(0, 0.15, -0.10), metal)
        _add_box("LauncherGrip", Vector3(0.10, 0.18, 0.10), Vector3(0, -0.14, 0.05), polymer)
    else:
        _add_box("Receiver", Vector3(body_width, body_height, receiver_length), Vector3(0, 0, 0), metal)
        _add_box("Handguard", Vector3(body_width * 0.88, body_height * 0.9, barrel_length), Vector3(0, 0, -0.34), dark)
        _add_box("Stock", Vector3(0.11, 0.12, 0.23), Vector3(0, -0.01, 0.34), polymer)
        _add_box("Magazine", magazine_size_visual, Vector3(0, -0.16, 0.03), dark)
        _add_box("PistolGrip", Vector3(0.075, 0.18, 0.09), Vector3(0, -0.14, 0.13), polymer)
        _add_box("TopRail", Vector3(0.055, 0.035, receiver_length + 0.10), Vector3(0, 0.085, -0.10), dark)
        if profile == "sniper" or profile == "dmr":
            _add_box("Optic", Vector3(0.09, 0.13, 0.24), Vector3(0, 0.18, -0.06), polymer)
            _add_box("ScopeTube", Vector3(0.065, 0.065, 0.22), Vector3(0, 0.22, -0.06), metal)
        if profile == "lmg":
            _add_box("AmmoBox", Vector3(0.18, 0.19, 0.22), Vector3(0, -0.20, 0.05), polymer)

    _add_box("Barrel", Vector3(0.045, 0.045, barrel_length), Vector3(0, 0, -0.62), metal)
    muzzle_light = OmniLight3D.new()
    muzzle_light.name = "MuzzleFlash"
    muzzle_light.position = Vector3(0, 0, -0.82)
    muzzle_light.light_color = Color(1.0, 0.58, 0.18)
    muzzle_light.light_energy = 0.0
    muzzle_light.omni_range = 4.0
    weapon_model.add_child(muzzle_light)
    weapon_model.position = weapon_home_position

func set_aiming(enabled: bool):
    aiming = enabled

func start_firing():
    trigger_held = true

func stop_firing():
    trigger_held = false

func fire(raycast: RayCast3D):
    if not can_fire or reloading or fire_cooldown > 0.0:
        return
    _fire_once(raycast)

func _process(delta):
    fire_cooldown = maxf(fire_cooldown - delta, 0.0)
    if trigger_held and fire_cooldown <= 0.0 and not reloading:
        var automatic := fire_mode.contains("AUTO")
        var raycast := get_parent().get_node_or_null("RayCast3D") as RayCast3D
        if is_instance_valid(raycast):
            _fire_once(raycast)
        if not automatic:
            trigger_held = false

    if is_instance_valid(weapon_model):
        var moving := false
        var player := get_parent().get_parent() as CharacterBody3D
        if is_instance_valid(player):
            moving = Vector2(player.velocity.x, player.velocity.z).length() > 0.25
        if moving and not aiming and not reloading:
            bob_time += delta * 10.0
        var bob := Vector3(sin(bob_time) * 0.012, absf(cos(bob_time)) * 0.012, 0) if moving and not aiming else Vector3.ZERO
        var target_position := weapon_aim_position if aiming else weapon_home_position
        target_position.y -= recoil_amount
        target_position += bob
        if reloading:
            target_position.y -= 0.10
            target_position.x += 0.08
        weapon_model.position = weapon_model.position.lerp(target_position, minf(delta * 12.0, 1.0))
        weapon_model.rotation.x = lerpf(weapon_model.rotation.x, -reload_visual * 0.35, minf(delta * 8.0, 1.0))
    recoil_amount = move_toward(recoil_amount, 0.0, delta * 0.8)
    reload_visual = move_toward(reload_visual, 1.0 if reloading else 0.0, delta * 2.0)

    if muzzle_timer > 0.0:
        muzzle_timer -= delta
        if muzzle_timer <= 0.0 and is_instance_valid(muzzle_light):
            muzzle_light.light_energy = 0.0

    if reloading:
        reload_remaining -= delta
        if reload_remaining <= 0.0:
            var needed := magazine_size - ammo_in_magazine
            var loaded := mini(needed, reserve_ammo)
            ammo_in_magazine += loaded
            reserve_ammo -= loaded
            reloading = false
            reload_visual = 0.0

func _fire_once(raycast: RayCast3D):
    if not can_fire or reloading or ammo_in_magazine <= 0:
        if ammo_in_magazine <= 0:
            trigger_held = false
        return
    ammo_in_magazine -= 1
    can_fire = false
    fire_cooldown = fire_rate
    recoil_amount = 0.075 if aiming else 0.12
    if is_instance_valid(weapon_model):
        weapon_model.rotation.x = -0.035 if aiming else -0.065
    if is_instance_valid(muzzle_light):
        muzzle_light.light_energy = 3.5
        muzzle_timer = 0.045

    raycast.force_raycast_update()
    if raycast.is_colliding():
        var target = raycast.get_collider()
        var hit_distance := raycast.global_position.distance_to(raycast.get_collision_point())
        if hit_distance <= effective_range:
            if target.has_method("take_damage"):
                target.take_damage(damage)
    can_fire = true

func reload():
    if reloading or ammo_in_magazine == magazine_size or reserve_ammo <= 0:
        return
    trigger_held = false
    reloading = true
    reload_remaining = reload_time
    reload_visual = 0.01
