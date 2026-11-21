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
var objective_bravo: Node3D
var mission_hud: CanvasLayer
var squad_label: Label

func _ready():
    print("HUNGER FOR WAR battlefield loaded!")
    _create_ground()
    _create_lighting()
    _create_battlefield_cover()
    _create_battlefield_environment()
    _create_terrain_features()
    _create_capture_objective()
    _create_second_objective()
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


func _create_second_objective():
    objective_bravo = objective_marker.duplicate()
    objective_bravo.name = "ObjectiveBravo"
    objective_bravo.position = Vector3(0, 0, -46)
    objective_bravo.visible = false
    add_child(objective_bravo)
    _make_cover("BravoSandbagsLeft", Vector3(3.0, 0.65, 0.65), Vector3(-5.0, 0.33, -43.0), Color(0.43, 0.40, 0.29))
    _make_cover("BravoSandbagsRight", Vector3(3.0, 0.65, 0.65), Vector3(5.0, 0.33, -43.0), Color(0.43, 0.40, 0.29))

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
        objective_label.text = "%s: %d%% — ENTER THE ZONE" % [objective_marker.name.to_upper(), int(percent)]

    if capture_progress >= capture_duration:
        if objective_marker == objective_bravo:
            objective_captured = true
            objective_label.text = "OBJECTIVE BRAVO SECURED"
            mission_label.text = "MISSION COMPLETE — BOTH OBJECTIVES SECURED"
            print("BOTH OBJECTIVES CAPTURED — MISSION COMPLETE")
        else:
            objective_marker.visible = false
            objective_marker = objective_bravo
            objective_marker.visible = true
            capture_progress = 0.0
            capture_bar.value = 0.0
            objective_label.text = "OBJECTIVE BRAVO ACTIVE — MOVE TO THE NEXT ZONE"
            mission_label.text = "MISSION: SECURE OBJECTIVE BRAVO"
            print("OBJECTIVE ALPHA SECURED — ADVANCE TO BRAVO")

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
    cover.add_to_group("battlefield_cover")
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


func _make_environment_box(parent: Node3D, object_name: String, size: Vector3, local_position: Vector3, material: Material, collision_enabled: bool = true):
    var holder: Node3D
    if collision_enabled:
        var body := StaticBody3D.new()
        body.name = object_name
        body.position = local_position
        body.add_to_group("battlefield_cover")
        parent.add_child(body)
        holder = body
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
    else:
        var node := Node3D.new()
        node.name = object_name
        node.position = local_position
        parent.add_child(node)
        holder = node
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = object_name + "Mesh"
    var box := BoxMesh.new()
    box.size = size
    mesh_instance.mesh = box
    mesh_instance.material_override = material
    holder.add_child(mesh_instance)
    return holder

func _make_building(building_name: String, center: Vector3, footprint: Vector2, wall_height: float, wall_material: Material, roof_material: Material, door_side: String = "front"):
    var building := Node3D.new()
    building.name = building_name
    building.position = center
    add_child(building)
    var width := footprint.x
    var depth := footprint.y
    var wall := 0.32
    var half_w := width * 0.5
    var half_d := depth * 0.5
    var door_width := 1.8
    var door_height := 2.25
    var window_width := 1.5
    var window_height := 1.0
    var window_y := 1.75

    # Concrete foundation and interior floor.
    _make_environment_box(building, "ConcreteFoundation", Vector3(width, 0.28, depth), Vector3(0, 0.14, 0), roof_material)
    _make_environment_box(building, "InteriorFloor", Vector3(width - 0.5, 0.12, depth - 0.5), Vector3(0, 0.34, 0), wall_material, false)

    # Rear wall, with a broad window opening.
    var side_segment := (width - window_width) * 0.5
    _make_environment_box(building, "RearWallLeft", Vector3(side_segment, wall_height, wall), Vector3(-(window_width + side_segment) * 0.5, wall_height * 0.5 + 0.28, -half_d), wall_material)
    _make_environment_box(building, "RearWallRight", Vector3(side_segment, wall_height, wall), Vector3((window_width + side_segment) * 0.5, wall_height * 0.5 + 0.28, -half_d), wall_material)
    _make_environment_box(building, "RearWindowLintel", Vector3(window_width, wall_height - window_y - window_height * 0.5, wall), Vector3(0, window_y + window_height * 0.5 + (wall_height - window_y - window_height * 0.5) * 0.5 + 0.28, -half_d), wall_material)
    _make_environment_box(building, "RearWindowSill", Vector3(window_width, window_y - window_height * 0.5 + 0.28, wall), Vector3(0, (window_y - window_height * 0.5 + 0.28) * 0.5, -half_d), wall_material)

    # Front wall has a walk-through doorway.
    var front_segment := (width - door_width) * 0.5
    _make_environment_box(building, "FrontWallLeft", Vector3(front_segment, wall_height, wall), Vector3(-(door_width + front_segment) * 0.5, wall_height * 0.5 + 0.28, half_d), wall_material)
    _make_environment_box(building, "FrontWallRight", Vector3(front_segment, wall_height, wall), Vector3((door_width + front_segment) * 0.5, wall_height * 0.5 + 0.28, half_d), wall_material)
    _make_environment_box(building, "DoorLintel", Vector3(door_width, wall_height - door_height, wall), Vector3(0, door_height + (wall_height - door_height) * 0.5 + 0.28, half_d), wall_material)

    # Side walls include narrow firing / observation windows.
    for side in [-1.0, 1.0]:
        var x := side * half_w
        var segment_depth := (depth - window_width) * 0.5
        _make_environment_box(building, "SideWallFront", Vector3(wall, wall_height, segment_depth), Vector3(x, wall_height * 0.5 + 0.28, (window_width + segment_depth) * 0.5), wall_material)
        _make_environment_box(building, "SideWallRear", Vector3(wall, wall_height, segment_depth), Vector3(x, wall_height * 0.5 + 0.28, -(window_width + segment_depth) * 0.5), wall_material)
        _make_environment_box(building, "SideWindowLintel", Vector3(wall, wall_height - window_y - window_height * 0.5, window_width), Vector3(x, window_y + window_height * 0.5 + (wall_height - window_y - window_height * 0.5) * 0.5 + 0.28, 0), wall_material)
        _make_environment_box(building, "SideWindowSill", Vector3(wall, window_y - window_height * 0.5 + 0.28, window_width), Vector3(x, (window_y - window_height * 0.5 + 0.28) * 0.5, 0), wall_material)

    _make_environment_box(building, "FlatRoof", Vector3(width + 0.5, 0.28, depth + 0.5), Vector3(0, wall_height + 0.42, 0), roof_material)
    _make_environment_box(building, "RoofParapetFront", Vector3(width + 0.3, 0.48, 0.22), Vector3(0, wall_height + 0.78, half_d), roof_material)
    _make_environment_box(building, "RoofParapetRear", Vector3(width + 0.3, 0.48, 0.22), Vector3(0, wall_height + 0.78, -half_d), roof_material)
    _make_environment_box(building, "DoorFrame", Vector3(door_width + 0.16, 0.12, 0.12), Vector3(0, door_height + 0.30, half_d + 0.04), roof_material, false)

    # Exterior sandbag firing position beside each structure.
    _make_cover(building_name + "FrontSandbags", Vector3(3.4, 0.65, 0.65), center + Vector3(-half_w - 2.0, 0.33, half_d + 1.2), Color(0.43, 0.39, 0.28))
    return building

func _create_battlefield_environment():
    var road_material := StandardMaterial3D.new()
    road_material.albedo_color = Color(0.13, 0.14, 0.13)
    road_material.roughness = 1.0
    var concrete_material := StandardMaterial3D.new()
    concrete_material.albedo_color = Color(0.37, 0.37, 0.33)
    concrete_material.roughness = 0.96
    var plaster_material := StandardMaterial3D.new()
    plaster_material.albedo_color = Color(0.48, 0.43, 0.34)
    plaster_material.roughness = 0.95
    var roof_material := StandardMaterial3D.new()
    roof_material.albedo_color = Color(0.20, 0.22, 0.20)
    roof_material.roughness = 0.98
    var dark_material := StandardMaterial3D.new()
    dark_material.albedo_color = Color(0.075, 0.085, 0.08)
    dark_material.metallic = 0.25
    dark_material.roughness = 0.85
    var rust_material := StandardMaterial3D.new()
    rust_material.albedo_color = Color(0.24, 0.19, 0.14)
    rust_material.metallic = 0.35
    rust_material.roughness = 0.9
    var glass_material := StandardMaterial3D.new()
    glass_material.albedo_color = Color(0.10, 0.17, 0.18, 0.48)
    glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    glass_material.roughness = 0.22

    # A worn service road gives the map a readable route through the combat zone.
    _make_environment_box(self, "MainServiceRoad", Vector3(8.0, 0.035, 100.0), Vector3(0, 0.52, -4), road_material, false)
    _make_environment_box(self, "RoadShoulderLeft", Vector3(1.1, 0.045, 100.0), Vector3(-4.5, 0.53, -4), concrete_material, false)
    _make_environment_box(self, "RoadShoulderRight", Vector3(1.1, 0.045, 100.0), Vector3(4.5, 0.53, -4), concrete_material, false)

    # Low-rise concrete / plaster compounds, positioned away from the central spawn lane.
    _make_building("WestCommandBuilding", Vector3(-20, 0, -20), Vector2(11, 9), 3.6, plaster_material, roof_material)
    _make_building("EastBarracks", Vector3(20, 0, -29), Vector2(10, 8), 3.4, concrete_material, roof_material)
    _make_building("WestCheckpoint", Vector3(-21, 0, 13), Vector2(9, 8), 3.2, concrete_material, roof_material)
    _make_building("EastRuinedOutpost", Vector3(21, 0, 10), Vector2(10, 8), 3.1, plaster_material, roof_material)

    # Defensive fighting positions and military logistics props.
    _make_cover("NorthHescoBarrierA", Vector3(5.0, 1.25, 1.1), Vector3(-11, 0.62, -39), Color(0.40, 0.38, 0.29))
    _make_cover("NorthHescoBarrierB", Vector3(5.0, 1.25, 1.1), Vector3(11, 0.62, -39), Color(0.40, 0.38, 0.29))
    _make_cover("WestCheckpointBarrier", Vector3(4.0, 0.9, 0.8), Vector3(-13, 0.45, 9), Color(0.42, 0.39, 0.29))
    _make_cover("EastCheckpointBarrier", Vector3(4.0, 0.9, 0.8), Vector3(13, 0.45, 9), Color(0.42, 0.39, 0.29))

    # Burned-out vehicle silhouettes: collision is intentionally omitted from decorative pieces.
    var wreck := Node3D.new()
    wreck.name = "BurnedOutTransportWreck"
    wreck.position = Vector3(8.5, 0.7, -18)
    wreck.rotation.y = deg_to_rad(-18)
    add_child(wreck)
    _make_environment_box(wreck, "WreckHull", Vector3(2.3, 1.0, 4.2), Vector3.ZERO, dark_material, false)
    _make_environment_box(wreck, "WreckCab", Vector3(1.9, 0.9, 1.4), Vector3(0, 0.72, -1.05), rust_material, false)
    _make_environment_box(wreck, "WreckHood", Vector3(2.0, 0.18, 1.3), Vector3(0, 0.55, -1.65), rust_material, false)
    for side in [-1.0, 1.0]:
        for axle in [-1.25, 1.25]:
            var wheel := MeshInstance3D.new()
            var wheel_mesh := CylinderMesh.new()
            wheel_mesh.top_radius = 0.43
            wheel_mesh.bottom_radius = 0.43
            wheel_mesh.height = 0.22
            wheel.mesh = wheel_mesh
            wheel.rotation.z = PI * 0.5
            wheel.position = Vector3(side * 1.08, -0.2, axle)
            wheel.material_override = dark_material
            wreck.add_child(wheel)

    # Utility poles, cable runs, and scattered debris add scale to the settlement.
    for pole_x in [-31.0, -14.0, 14.0, 31.0]:
        var pole := MeshInstance3D.new()
        var pole_mesh := CylinderMesh.new()
        pole_mesh.top_radius = 0.09
        pole_mesh.bottom_radius = 0.13
        pole_mesh.height = 7.0
        pole.mesh = pole_mesh
        pole.position = Vector3(pole_x, 3.5, -5.0)
        pole.material_override = dark_material
        add_child(pole)
        var crossbar := MeshInstance3D.new()
        var cross_mesh := BoxMesh.new()
        cross_mesh.size = Vector3(2.1, 0.12, 0.12)
        crossbar.mesh = cross_mesh
        crossbar.position = Vector3(pole_x, 6.55, -5.0)
        crossbar.material_override = dark_material
        add_child(crossbar)

    # Rocky berms and scrub clusters break long sight lines at the map edges.
    for i in range(12):
        var x := -43.0 + float(i) * 7.8
        _make_cover("NorthBerm%02d" % i, Vector3(5.0, 1.1, 2.0), Vector3(x, 0.55, -46), Color(0.27, 0.28, 0.22))
        _make_cover("SouthBerm%02d" % i, Vector3(5.0, 0.9, 2.0), Vector3(x, 0.45, 46), Color(0.29, 0.28, 0.22))

    for i in range(18):
        var shrub := MeshInstance3D.new()
        var shrub_mesh := SphereMesh.new()
        shrub_mesh.radius = randf_range(0.35, 0.85)
        shrub_mesh.height = shrub_mesh.radius * 1.4
        shrub.mesh = shrub_mesh
        shrub.position = Vector3(randf_range(-42.0, 42.0), shrub_mesh.radius * 0.45, randf_range(-42.0, 42.0))
        var shrub_material := StandardMaterial3D.new()
        shrub_material.albedo_color = Color(0.17, 0.21, 0.14)
        shrub_material.roughness = 1.0
        shrub.material_override = shrub_material
        add_child(shrub)


func _make_tree(tree_name: String, position: Vector3, scale_factor: float = 1.0):
    var tree := Node3D.new()
    tree.name = tree_name
    tree.position = position
    add_child(tree)

    var trunk_body := StaticBody3D.new()
    trunk_body.name = "TrunkCollision"
    tree.add_child(trunk_body)
    var trunk_shape := CollisionShape3D.new()
    var trunk_cylinder := CylinderShape3D.new()
    trunk_cylinder.radius = 0.24 * scale_factor
    trunk_cylinder.height = 3.0 * scale_factor
    trunk_shape.shape = trunk_cylinder
    trunk_shape.position.y = 1.5 * scale_factor
    trunk_body.add_child(trunk_shape)
    trunk_body.add_to_group("battlefield_cover")

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.16 * scale_factor
    trunk_mesh.bottom_radius = 0.29 * scale_factor
    trunk_mesh.height = 3.0 * scale_factor
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.5 * scale_factor
    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color(0.22, 0.17, 0.12)
    bark.roughness = 1.0
    trunk.material_override = bark
    tree.add_child(trunk)

    var foliage := StandardMaterial3D.new()
    foliage.albedo_color = Color(0.10, 0.17, 0.11)
    foliage.roughness = 1.0
    for layer in range(3):
        var crown := MeshInstance3D.new()
        var crown_mesh := ConeMesh.new()
        crown_mesh.top_radius = 0.05 * scale_factor
        crown_mesh.bottom_radius = (1.75 - float(layer) * 0.28) * scale_factor
        crown_mesh.height = 2.25 * scale_factor
        crown.mesh = crown_mesh
        crown.position.y = (3.0 + float(layer) * 0.82) * scale_factor
        crown.material_override = foliage
        tree.add_child(crown)


func _create_terrain_features():
    var earth_material := StandardMaterial3D.new()
    earth_material.albedo_color = Color(0.28, 0.27, 0.21)
    earth_material.roughness = 1.0
    var rock_material := StandardMaterial3D.new()
    rock_material.albedo_color = Color(0.31, 0.32, 0.29)
    rock_material.roughness = 1.0
    var road_paint := StandardMaterial3D.new()
    road_paint.albedo_color = Color(0.62, 0.59, 0.48)
    road_paint.roughness = 1.0

    # Broken center markings and faded edge lines make the service road readable.
    for z in range(-48, 45, 12):
        _make_environment_box(self, "RoadCenterMark%d" % z, Vector3(0.12, 0.018, 4.0), Vector3(0, 0.56, float(z)), road_paint, false)
    _make_environment_box(self, "RoadEdgeLineLeft", Vector3(0.09, 0.018, 92.0), Vector3(-3.65, 0.56, -4), road_paint, false)
    _make_environment_box(self, "RoadEdgeLineRight", Vector3(0.09, 0.018, 92.0), Vector3(3.65, 0.56, -4), road_paint, false)

    # Raised earth shoulders and shallow drainage banks shape the approaches.
    for side in [-1.0, 1.0]:
        for index in range(5):
            var z_pos := -38.0 + float(index) * 18.0
            var bank := _make_environment_box(self, "DrainageBank_%d_%d" % [int(side), index], Vector3(3.8, 0.7, 5.5), Vector3(side * 31.5, 0.28, z_pos), earth_material)
            bank.rotation.y = deg_to_rad(side * 8.0)
    _make_cover("SouthApproachEarthwork", Vector3(20.0, 0.8, 2.5), Vector3(0, 0.4, 39), earth_material.albedo_color)

    # Rock clusters and low scrub provide intermediate cover without blocking the main road.
    for i in range(14):
        var rock := MeshInstance3D.new()
        var rock_mesh := SphereMesh.new()
        var radius := randf_range(0.45, 1.15)
        rock_mesh.radius = radius
        rock_mesh.height = radius * 1.25
        rock.mesh = rock_mesh
        var side := -1.0 if i % 2 == 0 else 1.0
        rock.position = Vector3(side * randf_range(25.0, 43.0), radius * 0.42, randf_range(-42.0, 42.0))
        rock.scale = Vector3(randf_range(1.0, 1.8), 0.7, randf_range(0.9, 1.5))
        rock.material_override = rock_material
        add_child(rock)

    # Tree lines frame the settlement and create concealed flanking routes.
    var tree_index := 0
    for side in [-1.0, 1.0]:
        for z_pos in [-39.0, -27.0, -14.0, 2.0, 20.0, 35.0, 43.0]:
            var x_pos := side * (37.0 + randf_range(-2.0, 2.0))
            _make_tree("PerimeterPine%d" % tree_index, Vector3(x_pos, 0.5, z_pos), randf_range(0.82, 1.18))
            tree_index += 1
    for x_pos in [-27.0, -12.0, 12.0, 27.0]:
        _make_tree("NorthTree%d" % int(x_pos), Vector3(x_pos, 0.5, -43.0), randf_range(0.8, 1.05))
        _make_tree("SouthTree%d" % int(x_pos), Vector3(x_pos, 0.5, 43.0), randf_range(0.8, 1.05))

    # A few practical props make the compounds feel occupied.
    var crate_material := StandardMaterial3D.new()
    crate_material.albedo_color = Color(0.25, 0.22, 0.16)
    crate_material.roughness = 1.0
    var metal_material := StandardMaterial3D.new()
    metal_material.albedo_color = Color(0.18, 0.21, 0.19)
    metal_material.metallic = 0.35
    metal_material.roughness = 0.82
    _make_environment_box(self, "CommandSupplyCrates", Vector3(1.2, 0.9, 0.9), Vector3(-17.0, 0.95, -16.0), crate_material)
    _make_environment_box(self, "BarracksStorageCrates", Vector3(1.0, 0.8, 1.0), Vector3(17.0, 0.9, -25.0), crate_material)
    _make_environment_box(self, "CheckpointGenerator", Vector3(1.2, 0.9, 0.8), Vector3(-15.0, 0.95, 15.0), metal_material)
    _make_environment_box(self, "OutpostFuelDrums", Vector3(0.65, 1.0, 0.65), Vector3(17.0, 1.0, 13.0), rust_material if false else crate_material)

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
