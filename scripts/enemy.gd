extends CharacterBody3D

@export var max_health: float = 100.0
@export var move_speed: float = 2.5
@export var attack_range: float = 2.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.2

var health: float = 100.0
var gravity: float = 20.0
var attack_timer: float = 0.0
var player: CharacterBody3D

func _ready():
    health = max_health
    player = get_tree().get_first_node_in_group("player") as CharacterBody3D
    _build_soldier_appearance()

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
        _add_capsule_part("UpperArm", 0.14, 0.62, Vector3(side * 0.48, 1.12, 0), uniform)
        _add_capsule_part("Forearm", 0.12, 0.55, Vector3(side * 0.48, 0.72, -0.04), armor)
        _add_capsule_part("Thigh", 0.19, 0.72, Vector3(side * 0.20, 0.38, 0), uniform)
        _add_capsule_part("Boot", 0.13, 0.30, Vector3(side * 0.20, 0.08, -0.08), dark_gear)
        _add_box_part("ShoulderPad", Vector3(0.32, 0.20, 0.34), Vector3(side * 0.46, 1.42, 0), armor)

func _physics_process(delta):
    attack_timer = max(attack_timer - delta, 0.0)

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
        velocity.x = 0.0
        velocity.z = 0.0
        move_and_slide()
        return

    var to_player = player.global_position - global_position
    to_player.y = 0.0
    var distance = to_player.length()

    if distance > 0.1:
        look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

    if distance > attack_range:
        var direction = to_player.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
    else:
        velocity.x = 0.0
        velocity.z = 0.0
        if attack_timer <= 0.0 and player.has_method("take_damage"):
            player.take_damage(attack_damage)
            attack_timer = attack_cooldown

    move_and_slide()

func take_damage(amount: float):
    health -= amount
    print("Enemy hit! Health: ", health)
    if health <= 0.0:
        die()

func die():
    print("Enemy eliminated!")
    queue_free()
