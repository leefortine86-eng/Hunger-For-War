extends CharacterBody3D

@export var max_health: float = 100.0
@export var move_speed: float = 2.5
@export var preferred_range: float = 11.0
@export var fire_range: float = 28.0
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 1.15
@export var accuracy: float = 0.82

var health: float = 100.0
var gravity: float = 20.0
var attack_timer: float = 0.0
var player: CharacterBody3D
var muzzle_light: OmniLight3D
var muzzle_flash_time: float = 0.0
var cover_target := Vector3.ZERO
var has_cover_target: bool = false
var cover_hold_timer: float = 0.0
var walk_cycle: float = 0.0
var animated_arms: Array = []
var animated_legs: Array = []

func _ready():
    health = max_health
    player = get_tree().get_first_node_in_group("player") as CharacterBody3D
    _build_soldier_appearance()
    _build_enemy_rifle()

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.88
    return material

func _add_box_part(part_name: String, size: Vector3, part_position: Vector3, color: Color):
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := BoxMesh.new()
    mesh.size = size
    part.mesh = mesh
    part.position = part_position
    part.material_override = _material(color)
    add_child(part)
    return part

func _add_capsule_part(part_name: String, radius: float, height: float, part_position: Vector3, color: Color):
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    part.mesh = mesh
    part.position = part_position
    part.material_override = _material(color)
    add_child(part)
    return part

func _build_soldier_appearance():
    var uniform := Color(0.20, 0.25, 0.16)
    var dark_gear := Color(0.10, 0.13, 0.11)
    var armor := Color(0.27, 0.31, 0.23)
    var skin := Color(0.48, 0.35, 0.25)

    $Body.mesh = CapsuleMesh.new()
    $Body.material_override = _material(uniform)
    $Head.mesh = SphereMesh.new()
    $Head.material_override = _material(skin)

    _add_box_part("TacticalVest", Vector3(0.72, 0.62, 0.34), Vector3(0, 1.02, -0.04), armor)
    _add_box_part("ChestPlate", Vector3(0.48, 0.32, 0.12), Vector3(0, 1.12, -0.235), dark_gear)
    _add_box_part("Backpack", Vector3(0.48, 0.62, 0.24), Vector3(0, 1.18, 0.30), dark_gear)
    _add_capsule_part("Helmet", 0.29, 0.28, Vector3(0, 2.08, 0), Color(0.18, 0.22, 0.15))
    _add_box_part("HelmetBrim", Vector3(0.56, 0.07, 0.48), Vector3(0, 1.99, -0.02), dark_gear)

    for side in [-1.0, 1.0]:
        var upper_arm = _add_capsule_part("UpperArm", 0.14, 0.62, Vector3(side * 0.48, 1.12, 0), uniform)
        animated_arms.append(upper_arm)
        _add_capsule_part("Forearm", 0.12, 0.55, Vector3(side * 0.48, 0.72, -0.04), armor)
        var thigh = _add_capsule_part("Thigh", 0.19, 0.72, Vector3(side * 0.20, 0.38, 0), uniform)
        animated_legs.append(thigh)
        _add_capsule_part("Boot", 0.13, 0.30, Vector3(side * 0.20, 0.08, -0.08), dark_gear)
        _add_box_part("ShoulderPad", Vector3(0.32, 0.20, 0.34), Vector3(side * 0.46, 1.42, 0), armor)


func _build_enemy_rifle():
    var rifle := MeshInstance3D.new()
    rifle.name = "EnemyRifle"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.10, 0.10, 0.78)
    rifle.mesh = mesh
    rifle.position = Vector3(0.0, 1.12, -0.48)
    rifle.material_override = _material(Color(0.07, 0.08, 0.07))
    add_child(rifle)

    muzzle_light = OmniLight3D.new()
    muzzle_light.position = Vector3(0.0, 1.12, -0.90)
    muzzle_light.light_color = Color(1.0, 0.55, 0.18)
    muzzle_light.light_energy = 0.0
    muzzle_light.omni_range = 3.0
    add_child(muzzle_light)

func _has_line_of_sight(target_position: Vector3) -> bool:
    var query := PhysicsRayQueryParameters3D.create(
        global_position + Vector3(0, 1.25, 0),
        target_position
    )
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return hit.is_empty() or hit.get("collider") == player

func _fire_at_player():
    if not is_instance_valid(player):
        return
    var aim_point = player.global_position + Vector3(0, 0.8, 0)
    if not _has_line_of_sight(aim_point):
        return

    if is_instance_valid(muzzle_light):
        muzzle_light.light_energy = 2.8
        muzzle_flash_time = 0.06

    var spread := Vector3(
        randf_range(-1.0, 1.0),
        randf_range(-0.7, 0.7),
        randf_range(-1.0, 1.0)
    ) * (1.0 - accuracy) * 2.2
    var shot_target = aim_point + spread
    var query := PhysicsRayQueryParameters3D.create(
        global_position + Vector3(0, 1.25, 0),
        shot_target
    )
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty() and hit.get("collider") == player:
        player.take_damage(attack_damage)


func _find_cover_position() -> bool:
    if not is_instance_valid(player):
        return false
    var best_distance := 100000.0
    var found_cover := false
    for cover in get_tree().get_nodes_in_group("battlefield_cover"):
        if not is_instance_valid(cover):
            continue
        var away_from_player := cover.global_position - player.global_position
        away_from_player.y = 0.0
        if away_from_player.length() < 0.1:
            continue
        var candidate := cover.global_position + away_from_player.normalized() * 1.6
        candidate.y = global_position.y
        var distance_to_cover := global_position.distance_to(candidate)
        var distance_to_player := candidate.distance_to(player.global_position)
        if distance_to_cover > 16.0 or distance_to_player < 5.0:
            continue
        var query := PhysicsRayQueryParameters3D.create(
            candidate + Vector3(0, 1.1, 0),
            player.global_position + Vector3(0, 0.9, 0)
        )
        query.exclude = [get_rid()]
        var hit := get_world_3d().direct_space_state.intersect_ray(query)
        if not hit.is_empty() and hit.get("collider") == cover and distance_to_cover < best_distance:
            best_distance = distance_to_cover
            cover_target = candidate
            found_cover = true
    has_cover_target = found_cover
    if found_cover:
        cover_hold_timer = 5.0
    return found_cover

func _physics_process(delta):
    attack_timer = max(attack_timer - delta, 0.0)
    if muzzle_flash_time > 0.0:
        muzzle_flash_time -= delta
        if muzzle_flash_time <= 0.0 and is_instance_valid(muzzle_light):
            muzzle_light.light_energy = 0.0

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
        velocity.x = 0.0
        velocity.z = 0.0
        move_and_slide()
        _animate_soldier(delta)
        return

    var to_player = player.global_position - global_position
    to_player.y = 0.0
    var distance = to_player.length()

    if distance > 0.1:
        look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

    if has_cover_target and cover_hold_timer > 0.0:
        var to_cover := cover_target - global_position
        to_cover.y = 0.0
        if to_cover.length() > 1.15:
            var cover_direction := to_cover.normalized()
            velocity.x = cover_direction.x * move_speed * 1.15
            velocity.z = cover_direction.z * move_speed * 1.15
        else:
            velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 5.0)
            velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 5.0)
            cover_hold_timer -= delta
        if distance <= fire_range and attack_timer <= 0.0:
            _fire_at_player()
            attack_timer = attack_cooldown
        move_and_slide()
        _animate_soldier(delta)
        if cover_hold_timer <= 0.0:
            has_cover_target = false
        return

    if distance > preferred_range + 2.0:
        var direction = to_player.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
    elif distance < preferred_range - 3.0:
        var retreat = -to_player.normalized()
        velocity.x = retreat.x * move_speed * 0.65
        velocity.z = retreat.z * move_speed * 0.65
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 4.0)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 4.0)

    if distance <= fire_range and attack_timer <= 0.0:
        _fire_at_player()
        attack_timer = attack_cooldown

    move_and_slide()
    _animate_soldier(delta)

func _animate_soldier(delta: float):
    var speed := Vector2(velocity.x, velocity.z).length()
    if speed > 0.15:
        walk_cycle += delta * speed * 2.6
    else:
        walk_cycle = lerpf(walk_cycle, 0.0, minf(delta * 3.0, 1.0))
    var swing := sin(walk_cycle) * minf(speed / move_speed, 1.0) * 0.38
    for i in range(animated_arms.size()):
        var arm = animated_arms[i]
        var leg = animated_legs[i]
        arm.rotation.x = lerpf(arm.rotation.x, swing if i == 0 else -swing, minf(delta * 8.0, 1.0))
        leg.rotation.x = lerpf(leg.rotation.x, -swing if i == 0 else swing, minf(delta * 8.0, 1.0))

func take_damage(amount: float):
    health -= amount
    _find_cover_position()
    print("Enemy hit! Health: ", health)
    if health <= 0.0:
        die()

func die():
    print("Enemy eliminated!")
    queue_free()
