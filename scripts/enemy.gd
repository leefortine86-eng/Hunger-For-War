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

    var body_mesh = CapsuleMesh.new()
    body_mesh.radius = 0.4
    body_mesh.height = 1.8
    $Body.mesh = body_mesh

    var body_material = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.22, 0.28, 0.18)
    $Body.material_override = body_material

    var head_mesh = SphereMesh.new()
    head_mesh.radius = 0.25
    head_mesh.height = 0.5
    $Head.mesh = head_mesh

    var head_material = StandardMaterial3D.new()
    head_material.albedo_color = Color(0.55, 0.42, 0.32)
    $Head.material_override = head_material

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
            print("Enemy attacked the player!")

    move_and_slide()

func take_damage(amount: float):
    health -= amount
    print("Enemy hit! Health: ", health)
    if health <= 0.0:
        die()

func die():
    print("Enemy eliminated!")
    queue_free()
