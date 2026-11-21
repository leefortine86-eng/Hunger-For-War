extends Node3D

@export var damage: float = 25.0
@export var fire_rate: float = 0.12
@export var magazine_size: int = 30
@export var reserve_ammo: int = 120
@export var reload_time: float = 2.0

var ammo_in_magazine: int = 30
var can_fire: bool = true
var reloading: bool = false
var aiming: bool = false
var recoil_amount: float = 0.0
var muzzle_timer: float = 0.0
var weapon_home_position := Vector3(0.28, -0.25, -0.55)
var weapon_aim_position := Vector3(0.0, -0.16, -0.42)
var muzzle_light: OmniLight3D
var weapon_model: Node3D

func _ready():
    ammo_in_magazine = magazine_size
    _build_first_person_rifle()

func _material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = 0.55
    return material

func _add_box(name: String, size: Vector3, pos: Vector3, color: Color):
    var part := MeshInstance3D.new()
    part.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    part.mesh = mesh
    part.position = pos
    part.material_override = _material(color)
    weapon_model.add_child(part)
    return part

func _build_first_person_rifle():
    weapon_model = Node3D.new()
    weapon_model.name = "FirstPersonRifle"
    add_child(weapon_model)

    var dark := Color(0.075, 0.085, 0.078)
    var metal := Color(0.20, 0.22, 0.20)
    var grip := Color(0.11, 0.12, 0.10)
    _add_box("UpperReceiver", Vector3(0.12, 0.13, 0.48), Vector3(0, 0, 0), metal)
    _add_box("Handguard", Vector3(0.105, 0.115, 0.34), Vector3(0, 0.005, -0.34), dark)
    _add_box("Stock", Vector3(0.11, 0.12, 0.22), Vector3(0, -0.005, 0.32), grip)
    _add_box("Magazine", Vector3(0.085, 0.22, 0.12), Vector3(0, -0.16, 0.02), dark)
    _add_box("PistolGrip", Vector3(0.075, 0.18, 0.09), Vector3(0, -0.14, 0.13), grip)
    _add_box("TopRail", Vector3(0.055, 0.035, 0.43), Vector3(0, 0.085, -0.12), dark)
    _add_box("FrontSight", Vector3(0.035, 0.07, 0.035), Vector3(0, 0.13, -0.40), metal)
    _add_box("RearSight", Vector3(0.04, 0.06, 0.035), Vector3(0, 0.12, 0.12), metal)
    _add_box("Barrel", Vector3(0.045, 0.045, 0.30), Vector3(0, 0.0, -0.65), metal)

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

func _process(delta):
    if is_instance_valid(weapon_model):
        var target_position = weapon_aim_position if aiming else weapon_home_position
        target_position.y -= recoil_amount
        weapon_model.position = weapon_model.position.lerp(target_position, min(delta * 12.0, 1.0))
        weapon_model.rotation.x = lerp(weapon_model.rotation.x, 0.0, min(delta * 10.0, 1.0))
    recoil_amount = move_toward(recoil_amount, 0.0, delta * 0.8)

    if muzzle_timer > 0.0:
        muzzle_timer -= delta
        if muzzle_timer <= 0.0 and is_instance_valid(muzzle_light):
            muzzle_light.light_energy = 0.0

func fire(raycast: RayCast3D):
    if not can_fire or reloading:
        return
    if ammo_in_magazine <= 0:
        print("Magazine empty! Press reload.")
        return

    ammo_in_magazine -= 1
    can_fire = false
    recoil_amount = 0.075 if aiming else 0.12
    weapon_model.rotation.x = -0.035 if aiming else -0.065
    if is_instance_valid(muzzle_light):
        muzzle_light.light_energy = 3.5
        muzzle_timer = 0.045

    raycast.force_raycast_update()
    if raycast.is_colliding():
        var target = raycast.get_collider()
        print("Hit: ", target.name)
        if target.has_method("take_damage"):
            target.take_damage(damage)

    await get_tree().create_timer(fire_rate).timeout
    can_fire = true

func reload():
    if reloading or ammo_in_magazine == magazine_size or reserve_ammo <= 0:
        return
    reloading = true
    await get_tree().create_timer(reload_time).timeout
    var needed = magazine_size - ammo_in_magazine
    var loaded = min(needed, reserve_ammo)
    ammo_in_magazine += loaded
    reserve_ammo -= loaded
    reloading = false
