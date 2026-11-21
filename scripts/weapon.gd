extends Node3D

const WEAPON_CATALOG = preload("res://scripts/weapon_catalog.gd")
const EXPLOSIVE_PROJECTILE = preload("res://scripts/explosive_projectile.gd")

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
var burst_shots_remaining: int = 0
var muzzle_flash_mesh: MeshInstance3D
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
var attachment_loadouts: Dictionary = {}
var attachments: Dictionary = {"optic":"none", "muzzle":"none", "underbarrel":"none", "utility":"none", "magazine":"standard"}
var base_magazine_size: int = 30
var base_reserve_ammo: int = 120
var base_effective_range: float = 400.0
var base_recoil_scale: float = 1.0
var suppressor_equipped: bool = false
var flashlight_equipped: bool = false
var laser_equipped: bool = false

signal weapon_changed(weapon_name: String, weapon_class: String)
signal hit_confirmed(killed: bool)

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
    base_magazine_size = magazine_size
    base_reserve_ammo = reserve_ammo
    base_effective_range = effective_range
    attachments = attachment_loadouts.get(current_weapon_id, {"optic":"none", "muzzle":"none", "underbarrel":"none", "utility":"none", "magazine":"standard"}).duplicate()
    _apply_attachment_stats()
    reloading = false
    trigger_held = false
    burst_shots_remaining = 0
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

func _add_cylinder(part_name: String, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    part.mesh = mesh
    part.position = pos
    part.rotation.x = PI * 0.5
    part.material_override = _material(color, 0.35)
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

    _add_cylinder("Barrel", 0.027, barrel_length, Vector3(0, 0, -0.62), metal)
    var muzzle_z := -0.62 - barrel_length * 0.5
    _add_cylinder("MuzzleDevice", 0.038, 0.10, Vector3(0, 0, muzzle_z - 0.035), dark)
    if profile not in ["pistol", "launcher", "bow"]:
        # Small receiver controls, reinforced stock pad, and side accessory rails.
        _add_box("EjectionPort", Vector3(0.012, 0.055, 0.15), Vector3(body_width * 0.52, 0.015, -0.04), dark)
        _add_box("ChargingHandle", Vector3(0.10, 0.035, 0.045), Vector3(0, 0.095, 0.20), metal)
        _add_box("StockButtpad", Vector3(0.12, 0.14, 0.045), Vector3(0, -0.01, 0.47), dark)
        _add_box("LeftHandguardRail", Vector3(0.035, 0.045, barrel_length * 0.78), Vector3(-body_width * 0.55, -0.005, -0.34), metal)
        _add_box("RightHandguardRail", Vector3(0.035, 0.045, barrel_length * 0.78), Vector3(body_width * 0.55, -0.005, -0.34), metal)
        _add_box("TriggerGuardFront", Vector3(0.025, 0.10, 0.025), Vector3(0, -0.16, 0.06), metal)
        _add_box("TriggerGuardBase", Vector3(0.025, 0.025, 0.13), Vector3(0, -0.205, 0.0), metal)
    _build_attachment_visuals(profile, dark, metal, polymer)
    muzzle_light = OmniLight3D.new()
    muzzle_light.name = "MuzzleFlash"
    muzzle_light.position = Vector3(0, 0, -0.82)
    muzzle_light.light_color = Color(1.0, 0.58, 0.18)
    muzzle_light.light_energy = 0.0
    muzzle_light.omni_range = 4.0
    weapon_model.add_child(muzzle_light)
    muzzle_flash_mesh = MeshInstance3D.new()
    muzzle_flash_mesh.name = "VisibleMuzzleFlash"
    var flash_mesh := SphereMesh.new()
    flash_mesh.radius = 0.075
    flash_mesh.height = 0.15
    muzzle_flash_mesh.mesh = flash_mesh
    muzzle_flash_mesh.position = Vector3(0, 0, -0.86)
    muzzle_flash_mesh.scale = Vector3(1.0, 1.0, 1.8)
    var flash_material := StandardMaterial3D.new()
    flash_material.albedo_color = Color(1.0, 0.62, 0.22)
    flash_material.emission_enabled = true
    flash_material.emission = Color(1.0, 0.42, 0.08)
    flash_material.emission_energy_multiplier = 3.0
    muzzle_flash_mesh.material_override = flash_material
    muzzle_flash_mesh.visible = false
    weapon_model.add_child(muzzle_flash_mesh)

    weapon_model.position = weapon_home_position + Vector3(0.22, -0.28, 0)

func get_attachment_options(slot: String) -> Array:
    var profile := str(current_weapon.get("profile", "rifle"))
    match slot:
        "optic":
            return [{"id":"none","name":"Iron sights"},{"id":"red_dot","name":"Red dot"},{"id":"holo","name":"Holographic"},{"id":"scope_4x","name":"4x optic"}] if profile in ["rifle","bullpup","dmr","sniper","lmg","smg"] else [{"id":"none","name":"Standard sights"}]
        "muzzle":
            return [{"id":"none","name":"Standard muzzle"},{"id":"suppressor","name":"Suppressor"}] if profile not in ["launcher","bow"] else [{"id":"none","name":"No attachment"}]
        "underbarrel":
            return [{"id":"none","name":"No grip"},{"id":"vertical_grip","name":"Vertical grip"},{"id":"angled_grip","name":"Angled grip"}] if profile in ["rifle","bullpup","dmr","lmg","smg"] else [{"id":"none","name":"No attachment"}]
        "utility":
            return [{"id":"none","name":"No utility"},{"id":"flashlight","name":"Flashlight"},{"id":"laser","name":"Laser"}] if profile not in ["launcher","bow"] else [{"id":"none","name":"No utility"}]
        "magazine":
            return [{"id":"standard","name":"Standard magazine"},{"id":"extended","name":"Extended magazine"}] if profile not in ["launcher","bow","sniper"] else [{"id":"standard","name":"Standard load"}]
    return []

func set_attachment(slot: String, attachment_id: String) -> void:
    var valid := false
    for option in get_attachment_options(slot):
        if str(option.get("id", "")) == attachment_id:
            valid = true
            break
    if not valid:
        return
    attachments[slot] = attachment_id
    attachment_loadouts[current_weapon_id] = attachments.duplicate()
    _apply_attachment_stats()
    _build_weapon_model()

func get_attachment_summary() -> String:
    var names: Array[String] = []
    for slot in ["optic", "muzzle", "underbarrel", "utility", "magazine"]:
        var selected := str(attachments.get(slot, "none"))
        if selected not in ["none", "standard"]:
            names.append(selected.replace("_", " ").capitalize())
    return " | ".join(names) if not names.is_empty() else "No attachments"

func _apply_attachment_stats() -> void:
    magazine_size = base_magazine_size
    reserve_ammo = maxi(reserve_ammo, base_reserve_ammo)
    effective_range = base_effective_range
    suppressor_equipped = attachments.get("muzzle", "none") == "suppressor"
    flashlight_equipped = attachments.get("utility", "none") == "flashlight"
    laser_equipped = attachments.get("utility", "none") == "laser"
    if attachments.get("magazine", "standard") == "extended":
        magazine_size = maxi(1, int(round(float(base_magazine_size) * 1.5)))
        reserve_ammo = maxi(reserve_ammo, base_reserve_ammo + int(round(float(base_magazine_size) * 1.5)))
    if attachments.get("optic", "none") == "scope_4x":
        effective_range *= 1.25
    elif attachments.get("optic", "none") in ["red_dot", "holo"]:
        effective_range *= 1.08

func _build_attachment_visuals(profile: String, dark: Color, metal: Color, polymer: Color) -> void:
    var optic := str(attachments.get("optic", "none"))
    if optic != "none" and profile not in ["pistol", "launcher", "bow"]:
        var optic_body := _add_box("Attachment_Optic", Vector3(0.09, 0.12, 0.17), Vector3(0, 0.17, -0.08), polymer)
        if optic == "scope_4x":
            optic_body.scale = Vector3(1.0, 1.35, 1.8)
            _add_box("Optic_Lens", Vector3(0.075, 0.075, 0.025), Vector3(0, 0.18, -0.19), Color(0.12, 0.28, 0.32))
        else:
            _add_box("Optic_Window", Vector3(0.07, 0.075, 0.025), Vector3(0, 0.19, -0.17), Color(0.12, 0.32, 0.34))
    if attachments.get("muzzle", "none") == "suppressor":
        _add_box("Suppressor", Vector3(0.075, 0.075, 0.25), Vector3(0, 0, -0.82), dark)
    var grip := str(attachments.get("underbarrel", "none"))
    if grip != "none":
        var grip_size := Vector3(0.07, 0.17, 0.075)
        var grip_pos := Vector3(0, -0.14, -0.35)
        if grip == "angled_grip":
            grip_pos = Vector3(0, -0.12, -0.38)
        _add_box("Attachment_Grip", grip_size, grip_pos, polymer)
    if flashlight_equipped:
        _add_box("Attachment_Flashlight", Vector3(0.075, 0.075, 0.14), Vector3(0.075, -0.07, -0.48), metal)
    if laser_equipped:
        _add_box("Attachment_Laser", Vector3(0.055, 0.055, 0.12), Vector3(-0.075, -0.07, -0.48), Color(0.55, 0.08, 0.06))
    if attachments.get("magazine", "standard") == "extended" and profile not in ["pistol", "launcher", "bow"]:
        _add_box("ExtendedMagazine", Vector3(0.09, 0.29, 0.12), Vector3(0, -0.19, 0.03), dark)

func set_aiming(enabled: bool):
    aiming = enabled

func start_firing():
    trigger_held = true
    if fire_mode.contains("BURST"):
        burst_shots_remaining = 3

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
        var burst := fire_mode.contains("BURST")
        var raycast := get_parent().get_node_or_null("RayCast3D") as RayCast3D
        if is_instance_valid(raycast):
            _fire_once(raycast)
        if burst:
            burst_shots_remaining -= 1
            if burst_shots_remaining <= 0:
                trigger_held = false
        elif not automatic:
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
        if muzzle_timer <= 0.0:
            if is_instance_valid(muzzle_light):
                muzzle_light.light_energy = 0.0
            if is_instance_valid(muzzle_flash_mesh):
                muzzle_flash_mesh.visible = false

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
    var profile := str(current_weapon.get("profile", "rifle"))
    var recoil_scale := 0.7 if profile == "pistol" else 1.35 if profile == "lmg" or profile == "shotgun" else 1.8 if profile == "sniper" or profile == "launcher" else 1.0
    if attachments.get("underbarrel", "none") == "vertical_grip":
        recoil_scale *= 0.78
    elif attachments.get("underbarrel", "none") == "angled_grip":
        recoil_scale *= 0.88
    recoil_amount = (0.075 if aiming else 0.12) * recoil_scale
    if is_instance_valid(weapon_model):
        weapon_model.rotation.x = -0.035 if aiming else -0.065
    if is_instance_valid(muzzle_light):
        muzzle_light.light_energy = 1.0 if suppressor_equipped else 3.5
        muzzle_timer = 0.045
    if is_instance_valid(muzzle_flash_mesh):
        muzzle_flash_mesh.visible = not suppressor_equipped

    if _is_explosive_weapon():
        _launch_explosive_projectile(raycast)
        can_fire = true
        return

    var spread_profile := str(current_weapon.get("profile", "rifle"))
    var spread := 0.003
    match spread_profile:
        "pistol":
            spread = 0.006
        "smg":
            spread = 0.007
        "dmr":
            spread = 0.0018
        "sniper":
            spread = 0.0008
        "lmg":
            spread = 0.009
        "shotgun":
            spread = 0.018
        "launcher":
            spread = 0.004
        "bow":
            spread = 0.002
    if aiming:
        spread *= 0.42
    var original_target := raycast.target_position
    raycast.target_position = Vector3(randf_range(-spread, spread) * 1000.0, randf_range(-spread, spread) * 1000.0, -1000.0)
    raycast.force_raycast_update()
    raycast.target_position = original_target
    if raycast.is_colliding():
        var target = raycast.get_collider()
        var hit_distance := raycast.global_position.distance_to(raycast.get_collision_point())
        if hit_distance <= effective_range:
            if target.has_method("take_damage"):
                var eliminated := bool(target.take_damage(damage))
                hit_confirmed.emit(eliminated)
    can_fire = true

func reload():
    if reloading or ammo_in_magazine == magazine_size or reserve_ammo <= 0:
        return
    trigger_held = false
    reloading = true
    reload_remaining = reload_time
    reload_visual = 0.01

func _is_explosive_weapon() -> bool:
    return current_weapon_id in ["mgl40", "rpg7", "maaws", "verba", "m72law", "m203", "gp25", "rpg22", "rpg75"]

func _launch_explosive_projectile(raycast: RayCast3D) -> void:
    var shooter := get_parent().get_parent() as CharacterBody3D
    var world := get_tree().current_scene
    if not is_instance_valid(shooter) or not is_instance_valid(world):
        return

    var camera := get_parent() as Camera3D
    var direction := -camera.global_basis.z
    var origin := camera.global_position + direction * 1.05 + Vector3(0.0, -0.04, 0.0)
    var speed := 48.0
    var gravity_value := 1.4
    var fuse := 8.0
    var radius := 6.5
    var projectile_damage := damage
    var kind := "rocket"

    match current_weapon_id:
        "mgl40":
            speed = 27.0
            gravity_value = 9.8
            fuse = 2.8
            radius = 5.5
            kind = "grenade"
        "m203", "gp25":
            speed = 25.0
            gravity_value = 9.8
            fuse = 2.6
            radius = 5.0
            kind = "grenade"
        "rpg7":
            speed = 42.0
            gravity_value = 1.2
            radius = 7.0
        "maaws":
            speed = 55.0
            gravity_value = 0.8
            radius = 7.5
        "m72law":
            speed = 40.0
            gravity_value = 1.0
            radius = 6.5
        "rpg22":
            speed = 43.0
            gravity_value = 1.0
            radius = 6.0
        "rpg75":
            speed = 38.0
            gravity_value = 1.1
            radius = 6.0
        "verba":
            speed = 62.0
            gravity_value = 0.2
            radius = 4.0
            projectile_damage = damage * 0.65

    var projectile := Node3D.new()
    projectile.set_script(EXPLOSIVE_PROJECTILE)
    world.add_child(projectile)
    projectile.call("configure", origin, direction, speed, gravity_value, fuse, radius, projectile_damage, kind, shooter, world)
