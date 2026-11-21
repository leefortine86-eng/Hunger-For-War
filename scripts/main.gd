extends Node3D

const ENEMY_SCENE = preload("res://scenes/enemy.tscn")
const FRIENDLY_SCRIPT = preload("res://scripts/friendly.gd")

@export var capture_duration: float = 20.0
@export var objective_radius: float = 5.5

var capture_progress: float = 0.0
var objective_captured: bool = false
var objective_contested: bool = false
var objective_label: Label
var mission_label: Label
var capture_bar: ProgressBar
var objective_marker: Node3D
var mission_hud: CanvasLayer
var squad_label: Label

func _ready():
    print("HUNGER FOR WAR battlefield loaded!")
    _create_ground()
    _create_lighting()
    _create_battlefield_cover()
    _create_capture_objective()
    _create_mission_hud()
    _spawn_enemies()
    _spawn_friendly_squad()


func _create_capture_objective():
    objective_marker = Node3D.new()
    objective_marker.name = "ObjectiveAlpha"
    objective_marker.position = Vector3(0, 0, -34)
    add_child(objective_marker)

    var zone := MeshInstance3D.new()
    var zone_mesh := CylinderMesh.new()
    zone_mesh.top_radius = objective_radius
    zone_mesh.bottom_radius = objective_radius
    zone_mesh.height = 0.035
    zone.mesh = zone_mesh
    var zone_material := StandardMaterial3D.new()
    zone_material.albedo_color = Color(0.15, 0.62, 0.28, 0.24)
    zone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    zone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    zone.material_override = zone_material
    zone.position.y = 0.03
    objective_marker.add_child(zone)

    var pole := MeshInstance3D.new()
    var pole_mesh := CylinderMesh.new()
    pole_mesh.top_radius = 0.045
    pole_mesh.bottom_radius = 0.055
    pole_mesh.height = 4.2
    pole.mesh = pole_mesh
    pole.position = Vector3(0, 2.1, 0)
    var pole_material := StandardMaterial3D.new()
    pole_material.albedo_color = Color(0.18, 0.19, 0.17)
    pole.material_override = pole_material
    objective_marker.add_child(pole)

    var flag := MeshInstance3D.new()
    var flag_mesh := BoxMesh.new()
    flag_mesh.size = Vector3(1.3, 0.75, 0.045)
    flag.mesh = flag_mesh
    flag.position = Vector3(0.68, 3.55, 0)
    var flag_material := StandardMaterial3D.new()
    flag_material.albedo_color = Color(0.16, 0.38, 0.20)
    flag.material_override = flag_material
    objective_marker.add_child(flag)

    _make_cover("ObjectiveSandbagsLeft", Vector3(3.2, 0.65, 0.65), Vector3(-5.5, 0.33, -31.0), Color(0.43, 0.40, 0.29))
    _make_cover("ObjectiveSandbagsRight", Vector3(3.2, 0.65, 0.65), Vector3(5.5, 0.33, -31.0), Color(0.43, 0.40, 0.29))

func _create_mission_hud():
    mission_hud = CanvasLayer.new()
    mission_hud.name = "MissionHUD"
    add_child(mission_hud)

    mission_label = Label.new()
    mission_label.position = Vector2(24, 92)
    mission_label.text = "MISSION: SECURE OBJECTIVE ALPHA"
    mission_label.add_theme_font_size_override("font_size", 20)
    mission_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.68))
    mission_hud.add_child(mission_label)

    objective_label = Label.new()
    objective_label.position = Vector2(24, 122)
    objective_label.text = "OBJECTIVE: 0% CAPTURED"
    objective_label.add_theme_font_size_override("font_size", 18)
    objective_label.add_theme_color_override("font_color", Color(0.88, 0.94, 0.88))
    mission_hud.add_child(objective_label)

    capture_bar = ProgressBar.new()
    capture_bar.position = Vector2(24, 153)
    capture_bar.size = Vector2(250, 18)
    capture_bar.min_value = 0.0
    capture_bar.max_value = 100.0
    capture_bar.value = 0.0
    capture_bar.show_percentage = false
    mission_hud.add_child(capture_bar)

    squad_label = Label.new()
    squad_label.position = Vector2(24, 181)
    squad_label.text = "SQUAD: 3 OPERATIVES"
    squad_label.add_theme_font_size_override("font_size", 17)
    squad_label.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0))
    mission_hud.add_child(squad_label)

func _process(delta):
    if is_instance_valid(squad_label):
        squad_label.text = "SQUAD: %d OPERATIVES" % get_tree().get_nodes_in_group("friendlies").size()
    if objective_captured:
        return

    var player = get_tree().get_first_node_in_group("player") as Node3D
    if not is_instance_valid(player):
        return

    var distance = Vector2(player.global_position.x - objective_marker.global_position.x, player.global_position.z - objective_marker.global_position.z).length()
    var player_in_zone = distance <= objective_radius

    objective_contested = false
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if is_instance_valid(enemy):
            var enemy_distance = Vector2(enemy.global_position.x - objective_marker.global_position.x, enemy.global_position.z - objective_marker.global_position.z).length()
            if enemy_distance <= objective_radius + 1.5:
                objective_contested = true
                break

    if player_in_zone and not objective_contested:
        capture_progress = min(capture_progress + delta, capture_duration)
    elif not player_in_zone and capture_progress > 0.0:
        capture_progress = max(capture_progress - delta * 0.25, 0.0)

    var percent = (capture_progress / capture_duration) * 100.0
    capture_bar.value = percent
    if objective_contested:
        objective_label.text = "OBJECTIVE CONTESTED — CLEAR ENEMIES"
    elif player_in_zone:
        objective_label.text = "CAPTURING OBJECTIVE: %d%%" % int(percent)
    else:
        objective_label.text = "OBJECTIVE: %d%% — ENTER THE ZONE" % int(percent)

    if capture_progress >= capture_duration:
        objective_captured = true
        objective_label.text = "OBJECTIVE ALPHA SECURED"
        mission_label.text = "MISSION COMPLETE — AREA SECURED"
        print("OBJECTIVE ALPHA CAPTURED — MISSION COMPLETE")

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
        enemy.add_to_group("enemies")
        add_child(enemy)

    print("Three enemy soldiers deployed!")

func _spawn_friendly_squad():
    var formation_positions := [
        Vector3(-2.0, 0.0, 2.5),
        Vector3(2.0, 0.0, 2.5),
        Vector3(0.0, 0.0, 4.0)
    ]
    for i in range(formation_positions.size()):
        var soldier := CharacterBody3D.new()
        soldier.name = "FriendlyOperative%d" % (i + 1)
        soldier.set_script(FRIENDLY_SCRIPT)
        soldier.set("formation_offset", formation_positions[i])
        soldier.position = formation_positions[i]
        add_child(soldier)
    print("Friendly fireteam deployed!")
