extends CharacterBody3D

@export var move_speed: float = 4.0
@export var follow_distance: float = 2.6
@export var fire_range: float = 24.0
@export var fire_cooldown: float = 1.6
@export var accuracy: float = 0.9

var player: CharacterBody3D
var formation_offset := Vector3.ZERO
var attack_timer: float = 0.0
var gravity: float = 20.0
var health: float = 100.0
var rifle: MeshInstance3D
var muzzle_light: OmniLight3D
var flash_timer: float = 0.0
var walk_cycle: float = 0.0
var animated_arms: Array = []
var animated_legs: Array = []

func _ready():
    add_to_group("friendlies")
    player = get_tree().get_first_node_in_group("player") as CharacterBody3D
    _build_soldier()

func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    return material

func _part(part_name: String, mesh: Mesh, pos: Vector3, color: Color):
    var part := MeshInstance3D.new()
    part.name = part_name
    part.mesh = mesh
    part.position = pos
    part.material_override = _mat(color)
    add_child(part)
    return part

func _build_soldier():
    # Friendly faction: woodland green kit with blue team-identification panels.
    var green := Color(0.13, 0.23, 0.15)
    var armor := Color(0.24, 0.32, 0.22)
    var dark := Color(0.07, 0.10, 0.09)
    var friendly_blue := Color(0.045, 0.24, 0.62)
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.34
    body_mesh.height = 1.25
    _part("Body", body_mesh, Vector3(0, 1.0, 0), green)
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.22
    head_mesh.height = 0.42
    _part("Head", head_mesh, Vector3(0, 1.82, 0), Color(0.48, 0.36, 0.27))
    var vest_mesh := BoxMesh.new()
    vest_mesh.size = Vector3(0.68, 0.55, 0.36)
    _part("PlateCarrier", vest_mesh, Vector3(0, 1.08, -0.04), armor)
    var chest_id_mesh := BoxMesh.new()
    chest_id_mesh.size = Vector3(0.22, 0.22, 0.04)
    _part("FriendlyChestMark", chest_id_mesh, Vector3(0, 1.18, -0.245), friendly_blue)
    var helmet_mesh := SphereMesh.new()
    helmet_mesh.radius = 0.27
    helmet_mesh.height = 0.30
    _part("WoodlandHelmet", helmet_mesh, Vector3(0, 2.02, 0), Color(0.12, 0.20, 0.13))
    var pack_mesh := BoxMesh.new()
    pack_mesh.size = Vector3(0.42, 0.55, 0.22)
    _part("Pack", pack_mesh, Vector3(0, 1.12, 0.28), dark)
    # Modern helmet accessories and low-profile eye protection.
    var helmet_mount := BoxMesh.new()
    helmet_mount.size = Vector3(0.13, 0.17, 0.12)
    _part("HelmetNVGMount", helmet_mount, Vector3(0, 2.02, -0.25), dark)
    var helmet_rail := BoxMesh.new()
    helmet_rail.size = Vector3(0.07, 0.11, 0.30)
    _part("HelmetRailLeft", helmet_rail, Vector3(-0.25, 2.02, 0), dark)
    _part("HelmetRailRight", helmet_rail, Vector3(0.25, 2.02, 0), dark)
    var goggles := BoxMesh.new()
    goggles.size = Vector3(0.40, 0.10, 0.08)
    _part("EyeProtection", goggles, Vector3(0, 1.91, -0.18), Color(0.09, 0.15, 0.14))
    var headset := BoxMesh.new()
    headset.size = Vector3(0.10, 0.20, 0.13)
    _part("HeadsetLeft", headset, Vector3(-0.24, 1.88, 0.02), dark)
    _part("HeadsetRight", headset, Vector3(0.24, 1.88, 0.02), dark)
    var pouch := BoxMesh.new()
    pouch.size = Vector3(0.18, 0.22, 0.15)
    for pouch_x in [-0.25, 0.0, 0.25]:
        _part("MagazinePouch", pouch, Vector3(pouch_x, 0.87, -0.24), dark)
    var medical := BoxMesh.new()
    medical.size = Vector3(0.18, 0.20, 0.15)
    _part("MedicalPouch", medical, Vector3(-0.35, 1.00, -0.12), Color(0.32, 0.36, 0.27))
    var radio_antenna := BoxMesh.new()
    radio_antenna.size = Vector3(0.035, 0.65, 0.035)
    _part("RadioAntenna", radio_antenna, Vector3(0.17, 1.72, 0.28), dark)
    # Irregular muted fabric panels suggest a woodland camouflage pattern.
    for camo_index in range(7):
        var camo_patch := BoxMesh.new()
        camo_patch.size = Vector3(randf_range(0.10, 0.22), randf_range(0.08, 0.18), 0.025)
        var camo_color := [Color(0.08, 0.15, 0.09), Color(0.27, 0.29, 0.18), Color(0.34, 0.31, 0.21)][camo_index % 3]
        _part("UniformCamoPanel", camo_patch, Vector3(randf_range(-0.23, 0.23), randf_range(0.78, 1.42), -0.225), camo_color)
    for side in [-1.0, 1.0]:
        var limb := CapsuleMesh.new()
        limb.radius = 0.13
        limb.height = 0.68
        var arm_part = _part("Arm", limb, Vector3(side * 0.43, 1.0, -0.12), green)
        animated_arms.append(arm_part)
        var band_mesh := BoxMesh.new()
        band_mesh.size = Vector3(0.29, 0.13, 0.34)
        _part("FriendlyBlueArmBand", band_mesh, Vector3(side * 0.43, 1.23, -0.12), friendly_blue)
        var sleeve_patch := BoxMesh.new()
        sleeve_patch.size = Vector3(0.20, 0.22, 0.28)
        _part("SleeveCamoPanel", sleeve_patch, Vector3(side * 0.43, 1.08, 0.02), Color(0.27, 0.29, 0.18))
        var leg := CapsuleMesh.new()
        leg.radius = 0.16
        leg.height = 0.78
        var leg_part = _part("Leg", leg, Vector3(side * 0.19, 0.39, 0.02), dark)
        animated_legs.append(leg_part)
        var knee_pad := BoxMesh.new()
        knee_pad.size = Vector3(0.30, 0.23, 0.15)
        _part("KneePad", knee_pad, Vector3(side * 0.19, 0.35, -0.13), dark)
        var boot_mesh := BoxMesh.new()
        boot_mesh.size = Vector3(0.26, 0.16, 0.36)
        _part("CombatBoot", boot_mesh, Vector3(side * 0.19, 0.08, -0.08), Color(0.08, 0.09, 0.08))
        var thigh_pouch := BoxMesh.new()
        thigh_pouch.size = Vector3(0.22, 0.28, 0.14)
        _part("ThighPouch", thigh_pouch, Vector3(side * 0.32, 0.52, -0.10), armor)
        var glove_mesh := BoxMesh.new()
        glove_mesh.size = Vector3(0.17, 0.15, 0.18)
        _part("CombatGlove", glove_mesh, Vector3(side * 0.43, 0.54, -0.10), dark)

    var gun_mesh := BoxMesh.new()
    gun_mesh.size = Vector3(0.09, 0.09, 0.72)
    rifle = _part("Rifle", gun_mesh, Vector3(0.18, 1.12, -0.48), dark)
    var stock_mesh := BoxMesh.new()
    stock_mesh.size = Vector3(0.13, 0.14, 0.30)
    _part("RifleStock", stock_mesh, Vector3(0.18, 1.10, -0.06), Color(0.12, 0.14, 0.12))
    var mag_mesh := BoxMesh.new()
    mag_mesh.size = Vector3(0.13, 0.30, 0.18)
    _part("RifleMagazine", mag_mesh, Vector3(0.18, 0.91, -0.42), dark)
    var optic_mesh := BoxMesh.new()
    optic_mesh.size = Vector3(0.14, 0.12, 0.18)
    _part("RifleOptic", optic_mesh, Vector3(0.18, 1.23, -0.40), Color(0.08, 0.10, 0.10))
    var foregrip_mesh := BoxMesh.new()
    foregrip_mesh.size = Vector3(0.10, 0.18, 0.12)
    _part("RifleForegrip", foregrip_mesh, Vector3(0.18, 0.99, -0.68), dark)
    muzzle_light = OmniLight3D.new()
    muzzle_light.position = Vector3(0.18, 1.12, -0.88)
    muzzle_light.light_color = Color(1.0, 0.58, 0.2)
    muzzle_light.light_energy = 0.0
    muzzle_light.omni_range = 2.8
    add_child(muzzle_light)

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.34
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)

func _nearest_enemy() -> Node3D:
    var nearest: Node3D
    var nearest_distance := fire_range
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate):
            continue
        var distance := global_position.distance_to(candidate.global_position)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest = candidate
    return nearest

func _can_hit(target: Node3D) -> bool:
    var start := global_position + Vector3(0, 1.2, 0)
    var finish := target.global_position + Vector3(0, 1.0, 0)
    var query := PhysicsRayQueryParameters3D.create(start, finish)
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return not hit.is_empty() and hit.get("collider") == target

func _fire_at(target: Node3D):
    if not is_instance_valid(target) or not _can_hit(target):
        return
    muzzle_light.light_energy = 2.4
    flash_timer = 0.055
    var aim := target.global_position + Vector3(0, 1.0, 0)
    aim += Vector3(randf_range(-0.45, 0.45), randf_range(-0.3, 0.3), randf_range(-0.45, 0.45)) * (1.0 - accuracy)
    var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.2, 0), aim)
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty() and hit.get("collider") == target:
        target.call("take_damage", 12.0)

func _physics_process(delta):
    attack_timer = maxf(attack_timer - delta, 0.0)
    if flash_timer > 0.0:
        flash_timer -= delta
        if flash_timer <= 0.0:
            muzzle_light.light_energy = 0.0

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
        move_and_slide()
        _animate_soldier(delta)
        return

    var desired_position := player.global_position + player.global_basis * formation_offset
    var to_formation := desired_position - global_position
    to_formation.y = 0.0
    var enemy := _nearest_enemy()

    if is_instance_valid(enemy):
        var to_enemy := enemy.global_position - global_position
        to_enemy.y = 0.0
        if to_enemy.length() > 0.1:
            look_at(Vector3(enemy.global_position.x, global_position.y, enemy.global_position.z), Vector3.UP)
        if to_enemy.length() > 8.0 and to_formation.length() > follow_distance:
            var direction := to_formation.normalized()
            velocity.x = direction.x * move_speed
            velocity.z = direction.z * move_speed
        else:
            velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 4.0)
            velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 4.0)
        if to_enemy.length() <= fire_range and attack_timer <= 0.0:
            _fire_at(enemy)
            attack_timer = fire_cooldown
    else:
        if to_formation.length() > follow_distance:
            var direction := to_formation.normalized()
            velocity.x = direction.x * move_speed
            velocity.z = direction.z * move_speed
            look_at(Vector3(desired_position.x, global_position.y, desired_position.z), Vector3.UP)
        else:
            velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 4.0)
            velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 4.0)

    move_and_slide()
    _animate_soldier(delta)

func _animate_soldier(delta: float):
    var speed := Vector2(velocity.x, velocity.z).length()
    if speed > 0.15:
        walk_cycle += delta * speed * 2.7
    else:
        walk_cycle = lerpf(walk_cycle, 0.0, minf(delta * 3.0, 1.0))
    var swing := sin(walk_cycle) * minf(speed / move_speed, 1.0) * 0.42
    for i in range(animated_arms.size()):
        var arm = animated_arms[i]
        var leg = animated_legs[i]
        arm.rotation.x = lerpf(arm.rotation.x, swing if i == 0 else -swing, minf(delta * 9.0, 1.0))
        leg.rotation.x = lerpf(leg.rotation.x, -swing if i == 0 else swing, minf(delta * 9.0, 1.0))

func take_damage(amount: float):
    health = maxf(health - amount, 0.0)
    if health <= 0.0:
        queue_free()
