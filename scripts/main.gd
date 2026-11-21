extends Node3D

const ENEMY_SCENE = preload("res://scenes/enemy.tscn")

func _ready():
    print("HUNGER FOR WAR battlefield loaded!")
    _create_ground()
    _create_lighting()
    _create_battlefield_cover()
    _spawn_enemies()

func _create_ground():
    var ground_body := StaticBody3D.new()
    ground_body.name = "BattlefieldGround"
    add_child(ground_body)

    var ground := MeshInstance3D.new()
    var ground_mesh := BoxMesh.new()
    ground_mesh.size = Vector3(100, 1, 100)
    ground.mesh = ground_mesh
    var ground_material := StandardMaterial3D.new()
    ground_material.albedo_color = Color(0.22, 0.25, 0.18)
    ground_material.roughness = 1.0
    ground.material_override = ground_material
    ground_body.add_child(ground)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(100, 1, 100)
    collision.shape = shape
    collision.position.y = -0.5
    ground_body.add_child(collision)

func _create_lighting():
    var sunlight := DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-48, -32, 0)
    sunlight.light_energy = 1.35
    sunlight.shadow_enabled = true
    add_child(sunlight)

    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.sky = Sky.new()
    environment.sky.sky_material = ProceduralSkyMaterial.new()
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.48, 0.51, 0.46)
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = environment
    add_child(world)

func _make_cover(name: String, size: Vector3, position: Vector3, color: Color):
    var cover := StaticBody3D.new()
    cover.name = name
    cover.position = position
    add_child(cover)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.95
    mesh_instance.material_override = material
    cover.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    cover.add_child(collision)

func _create_battlefield_cover():
    var sandbag := Color(0.43, 0.40, 0.29)
    var concrete := Color(0.34, 0.36, 0.33)
    var crate_color := Color(0.27, 0.22, 0.14)

    # Low sandbag defensive positions leave a clear central approach.
    _make_cover("LeftSandbagPosition", Vector3(4.0, 0.75, 0.8), Vector3(-6.0, 0.38, -8.0), sandbag)
    _make_cover("RightSandbagPosition", Vector3(4.0, 0.75, 0.8), Vector3(6.0, 0.38, -8.0), sandbag)
    _make_cover("FarConcreteBarrier", Vector3(7.0, 1.25, 0.7), Vector3(0.0, 0.63, -25.0), concrete)

    # Supply crates and broken wall sections along the edges of the combat lane.
    _make_cover("SupplyCrateA", Vector3(1.2, 1.2, 1.2), Vector3(-4.2, 0.6, -4.0), crate_color)
    _make_cover("SupplyCrateB", Vector3(1.2, 1.2, 1.2), Vector3(4.2, 0.6, -15.0), crate_color)
    _make_cover("BrokenWallLeft", Vector3(0.7, 1.8, 5.0), Vector3(-12.0, 0.9, -17.0), concrete)
    _make_cover("BrokenWallRight", Vector3(0.7, 1.8, 5.0), Vector3(12.0, 0.9, -17.0), concrete)

func _spawn_enemies():
    var spawn_points := [
        Vector3(0, 0, -12),
        Vector3(-5, 0, -20),
        Vector3(5, 0, -22)
    ]

    for spawn_position in spawn_points:
        var enemy = ENEMY_SCENE.instantiate()
        enemy.position = spawn_position
        add_child(enemy)

    print("Three enemy soldiers deployed!")
