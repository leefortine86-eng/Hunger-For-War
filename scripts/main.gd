
extends Node3D

const ENEMY_SCENE = preload("res://scenes/enemy.tscn")

func _ready():
    print("HUNGER FOR WAR battlefield loaded!")

    # Create solid battlefield ground
    var ground_body = StaticBody3D.new()
    ground_body.name = "BattlefieldGround"
    add_child(ground_body)

    var ground = MeshInstance3D.new()
    var ground_mesh = BoxMesh.new()
    ground_mesh.size = Vector3(100, 1, 100)
    ground.mesh = ground_mesh

    var ground_material = StandardMaterial3D.new()
    ground_material.albedo_color = Color(0.22, 0.28, 0.20)
    ground.material_override = ground_material
    ground_body.add_child(ground)

    var ground_collision = CollisionShape3D.new()
    var ground_shape = BoxShape3D.new()
    ground_shape.size = Vector3(100, 1, 100)
    ground_collision.shape = ground_shape
    ground_collision.position.y = -0.5
    ground_body.add_child(ground_collision)

    # Add sunlight
    var sunlight = DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-55, -30, 0)
    sunlight.light_energy = 1.5
    add_child(sunlight)

    # Add sky
    var world = WorldEnvironment.new()
    var environment = Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.sky = Sky.new()
    environment.sky.sky_material = ProceduralSkyMaterial.new()
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.55, 0.58, 0.62)
    world.environment = environment
    add_child(world)

    # Spawn first enemy
    var enemy = ENEMY_SCENE.instantiate()
    enemy.position = Vector3(0, 0, -12)
    add_child(enemy)

    print("Enemy soldier deployed!")


