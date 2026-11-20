

extends CharacterBody3D

@export var max_health: float = 100.0

var health: float = 100.0

func _ready():
    health = max_health

    # Create a visible soldier body
    var body_mesh = CapsuleMesh.new()
    body_mesh.radius = 0.4
    body_mesh.height = 1.8
    $Body.mesh = body_mesh

    var body_material = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.22, 0.28, 0.18)
    $Body.material_override = body_material

    # Create soldier head
    var head_mesh = SphereMesh.new()
    head_mesh.radius = 0.25
    head_mesh.height = 0.5
    $Head.mesh = head_mesh

    var head_material = StandardMaterial3D.new()
    head_material.albedo_color = Color(0.55, 0.42, 0.32)
    $Head.material_override = head_material

func take_damage(amount: float):
    health -= amount

    print("Enemy hit! Health: ", health)

    if health <= 0:
        die()

func die():
    print("Enemy eliminated!")
    queue_free()
