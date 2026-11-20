

extends Node3D

func _ready():
    print("HUNGER FOR WAR initialized!")

    # Create battlefield environment
    var ground = MeshInstance3D.new()
    var ground_mesh = PlaneMesh.new()
    ground_mesh.size = Vector2(100, 100)
    ground.mesh = ground_mesh
    add_child(ground)

    var ground_material = StandardMaterial3D.new()
    ground_material.albedo_color = Color(0.22, 0.28, 0.20)
    ground.material_override = ground_material

    # Create sunlight
    var sunlight = DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-55, -30, 0)
    sunlight.light_energy = 1.5
    add_child(sunlight)

    # Create sky environment
    var world = WorldEnvironment.new()
    var environment = Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.sky = Sky.new()
    environment.sky.sky_material = ProceduralSkyMaterial.new()
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.55, 0.58, 0.62)
    world.environment = environment
    add_child(world)
