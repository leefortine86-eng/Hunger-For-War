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
    var green := Color(0.16, 0.27, 0.19)
    var armor := Color(0.27, 0.34, 0.25)
    var dark := Color(0.08, 0.11, 0.10)
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
    var pack_mesh := BoxMesh.new()
    pack_mesh.size = Vector3(0.42, 0.55, 0.22)
    _part("Pack", pack_mesh, Vector3(0, 1.12, 0.28), dark)
    for side in [-1.0, 1.0]:
        var limb := CapsuleMesh.new()
        limb.radius = 0.13
        limb.height = 0.68
        _part("Arm", limb, Vector3(side * 0.43, 1.0, -0.12), green)
        var leg := CapsuleMesh.new()
        leg.radius = 0.16
        leg.height = 0.78
        _part("Leg", leg, Vector3(side * 0.19, 0.39, 0.02), dark)

    var gun_mesh := BoxMesh.new()
    gun_mesh.size = Vector3(0.09, 0.09, 0.72)
    rifle = _part("Rifle", gun_mesh, Vector3(0.18, 1.12, -0.48), dark)
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
        target.take_damage(12.0)

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

func take_damage(amount: float):
    health = maxf(health - amount, 0.0)
    if health <= 0.0:
        queue_free()
