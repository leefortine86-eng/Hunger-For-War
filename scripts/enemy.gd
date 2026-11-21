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
var flank_target := Vector3.ZERO
var flank_refresh_timer: float = 0.0
var squad_slot: int = 0
var walk_cycle: float = 0.0
var animated_arms: Array = []
var animated_forearms: Array = []
var animated_hands: Array = []
var animated_legs: Array = []
var pose_rig: Node
var glb_animator: Node
var rifle: MeshInstance3D
var weapon_mount: Node3D
var simulated_magazine: int = 8
var reload_pose_timer: float = 0.0
var hit_reaction_timer: float = 0.0
var is_eliminated: bool = false

func _ready():
    health = max_health
    player = get_tree().get_first_node_in_group("player") as CharacterBody3D
    squad_slot = get_tree().get_nodes_in_group("enemies").size()
    _build_soldier_appearance()
    _build_enemy_rifle()
    if is_instance_valid(glb_animator) and glb_animator.has_method("attach_weapon_to_hand"):
        glb_animator.attach_weapon_to_hand(weapon_mount)
    pose_rig = preload("res://scripts/soldier_skeleton_rig.gd").new()
    add_child(pose_rig)
    var fallback_weapon: Node3D = rifle if not is_instance_valid(glb_animator) else null
    pose_rig.configure(self, animated_arms, animated_forearms, animated_hands, animated_legs, fallback_weapon, "rifle")

func _camouflage_material(base: Color, dark_patch: Color, light_patch: Color) -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color;
uniform vec4 dark_color : source_color;
uniform vec4 light_color : source_color;
float hash_cell(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void fragment() {
    vec2 cell = floor(UV * vec2(24.0, 18.0));
    vec2 local_uv = fract(UV * vec2(24.0, 18.0));
    float seed = hash_cell(cell);
    float shape = smoothstep(0.18, 0.72, length((local_uv - vec2(0.5)) * vec2(0.85, 1.15)));
    vec3 fabric = base_color.rgb;
    if (seed > 0.60 && shape < 0.78) {
        fabric = dark_color.rgb;
    } else if (seed < 0.22 && shape < 0.70) {
        fabric = light_color.rgb;
    }
    float weave = 0.965 + 0.035 * sin(UV.x * 850.0) * sin(UV.y * 760.0);
    ALBEDO = fabric * weave;
    ROUGHNESS = 0.96;
}
"""
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("base_color", base)
    material.set_shader_parameter("dark_color", dark_patch)
    material.set_shader_parameter("light_color", light_patch)
    return material

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
    # Hostile faction: dusty tan/grey combat clothing with unmistakable red ID bands.
    var uniform := Color(0.43, 0.40, 0.33)
    var dark_gear := Color(0.12, 0.13, 0.13)
    var armor := Color(0.25, 0.26, 0.24)
    var skin := Color(0.48, 0.35, 0.25)
    var hostile_red := Color(0.62, 0.075, 0.045)
    var helmet_tan := Color(0.36, 0.34, 0.27)

    var torso := CapsuleMesh.new()
    torso.radius = 0.29
    torso.height = 1.16
    $Body.mesh = torso
    $Body.position = Vector3(0, 1.08, 0)
    $Body.material_override = _camouflage_material(uniform, Color(0.25, 0.25, 0.21), Color(0.53, 0.48, 0.38))
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.18
    head_mesh.height = 0.36
    $Head.mesh = head_mesh
    $Head.position = Vector3(0, 1.80, 0)
    $Head.material_override = _material(skin)
    _add_capsule_part("Neck", 0.105, 0.22, Vector3(0, 1.67, 0), skin)
    _add_box_part("CombatBelt", Vector3(0.62, 0.13, 0.34), Vector3(0, 0.70, -0.01), dark_gear)
    _add_box_part("Pelvis", Vector3(0.48, 0.28, 0.34), Vector3(0, 0.55, 0.01), uniform)

    _add_box_part("TacticalVest", Vector3(0.72, 0.62, 0.34), Vector3(0, 1.02, -0.04), armor)
    _add_box_part("ChestPlate", Vector3(0.48, 0.32, 0.12), Vector3(0, 1.12, -0.235), dark_gear)
    _add_box_part("Backpack", Vector3(0.48, 0.62, 0.24), Vector3(0, 1.18, 0.30), dark_gear)
    _add_capsule_part("Helmet", 0.29, 0.28, Vector3(0, 2.08, 0), helmet_tan)
    _add_box_part("HostileChestMark", Vector3(0.22, 0.24, 0.035), Vector3(0.0, 1.18, -0.305), hostile_red)
    _add_box_part("HostileArmBandLeft", Vector3(0.31, 0.13, 0.34), Vector3(-0.48, 1.25, -0.01), hostile_red)
    _add_box_part("HostileArmBandRight", Vector3(0.31, 0.13, 0.34), Vector3(0.48, 1.25, -0.01), hostile_red)
    _add_box_part("HostileShoulderPatch", Vector3(0.20, 0.18, 0.045), Vector3(0.0, 1.48, -0.20), hostile_red)
    _add_box_part("HelmetBrim", Vector3(0.56, 0.07, 0.48), Vector3(0, 1.99, -0.02), dark_gear)
    # Modern protective equipment: helmet rails, eye protection, headset and front NVG mount.
    _add_box_part("HelmetNVGMount", Vector3(0.13, 0.18, 0.12), Vector3(0, 2.02, -0.27), dark_gear)
    _add_box_part("HelmetSideRailLeft", Vector3(0.07, 0.12, 0.32), Vector3(-0.27, 2.04, 0), dark_gear)
    _add_box_part("HelmetSideRailRight", Vector3(0.07, 0.12, 0.32), Vector3(0.27, 2.04, 0), dark_gear)
    _add_box_part("EyeProtection", Vector3(0.42, 0.10, 0.09), Vector3(0, 1.91, -0.20), Color(0.10, 0.15, 0.15))
    _add_box_part("HeadsetLeft", Vector3(0.10, 0.22, 0.14), Vector3(-0.25, 1.88, 0.02), dark_gear)
    _add_box_part("HeadsetRight", Vector3(0.10, 0.22, 0.14), Vector3(0.25, 1.88, 0.02), dark_gear)
    # Magazine and utility pouches across the plate carrier.
    for pouch_x in [-0.25, 0.0, 0.25]:
        _add_box_part("MagazinePouch", Vector3(0.18, 0.22, 0.16), Vector3(pouch_x, 0.88, -0.25), dark_gear)
    _add_box_part("UtilityPouchLeft", Vector3(0.20, 0.24, 0.18), Vector3(-0.38, 0.98, -0.12), armor)
    _add_box_part("UtilityPouchRight", Vector3(0.20, 0.24, 0.18), Vector3(0.38, 0.98, -0.12), armor)
    _add_box_part("RadioAntenna", Vector3(0.035, 0.65, 0.035), Vector3(0.18, 1.72, 0.31), dark_gear)
    _add_box_part("TourniquetPouch", Vector3(0.17, 0.18, 0.14), Vector3(-0.36, 1.38, -0.10), hostile_red)

    for side in [-1.0, 1.0]:
        var upper_arm = _add_capsule_part("UpperArm", 0.125, 0.52, Vector3(side * 0.35, 1.34, -0.14), uniform)
        upper_arm.rotation.x = -0.72
        upper_arm.rotation.z = side * 0.32
        upper_arm.material_override = _camouflage_material(uniform, Color(0.25, 0.25, 0.21), Color(0.53, 0.48, 0.38))
        animated_arms.append(upper_arm)
        var forearm = _add_capsule_part("Forearm", 0.105, 0.48, Vector3(side * 0.16, 1.12, -0.47), uniform)
        forearm.rotation.x = -0.82
        forearm.rotation.z = side * 0.24
        animated_forearms.append(forearm)
        var hand_z := -0.70 if side < 0.0 else -0.39
        var hand = _add_capsule_part("GlovedHand", 0.085, 0.18, Vector3(side * 0.10, 1.02, hand_z), dark_gear)
        animated_hands.append(hand)
        for finger_index in range(4):
            var finger_z := hand_z - 0.075
            var finger_y := 0.99 - float(finger_index) * 0.012
            var finger_x := side * 0.10 + (float(finger_index) - 1.5) * 0.035
            _add_box_part("GloveFinger", Vector3(0.027, 0.045, 0.105), Vector3(finger_x, finger_y, finger_z), dark_gear)
        _add_box_part("GloveThumb", Vector3(0.045, 0.055, 0.12), Vector3(side * 0.18, 1.03, hand_z + 0.025), dark_gear)
        var thigh = _add_capsule_part("Thigh", 0.155, 0.68, Vector3(side * 0.20, 0.39, 0), uniform)
        animated_legs.append(thigh)
        _add_capsule_part("LowerLeg", 0.125, 0.48, Vector3(side * 0.20, 0.16, 0.015), uniform)
        _add_box_part("BootSole", Vector3(0.23, 0.07, 0.37), Vector3(side * 0.20, 0.045, -0.10), Color(0.035, 0.04, 0.035))
        _add_box_part("CombatBoot", Vector3(0.22, 0.17, 0.34), Vector3(side * 0.20, 0.13, -0.08), dark_gear)
        _add_box_part("ShoulderPad", Vector3(0.32, 0.20, 0.34), Vector3(side * 0.46, 1.42, 0), armor)
        _add_box_part("SleeveCamouflagePanel", Vector3(0.20, 0.24, 0.30), Vector3(side * 0.49, 1.23, 0.01), uniform)
        _add_box_part("KneePad", Vector3(0.31, 0.25, 0.16), Vector3(side * 0.20, 0.35, -0.14), dark_gear)
        _add_box_part("ThighUtilityPouch", Vector3(0.24, 0.30, 0.16), Vector3(side * 0.34, 0.53, -0.10), armor)
        _add_box_part("Glove", Vector3(0.18, 0.16, 0.20), Vector3(side * 0.48, 0.52, -0.05), dark_gear)

    # Prefer the uploaded textured soldier as the enemy's visible character.
    # Keep the procedural model as a fallback if Godot cannot load the GLB.
    var soldier_scene := load("res://assets/characters/Military_Male_03.glb") as PackedScene
    if soldier_scene != null:
        var soldier_model := soldier_scene.instantiate()
        soldier_model.name = "MilitaryMale03"
        add_child(soldier_model)
        for child in get_children():
            if child is MeshInstance3D and child != rifle:
                child.visible = false
        var animator := Node3D.new()
        animator.name = "GLBSoldierAnimator"
        animator.set_script(load("res://scripts/glb_soldier_animator.gd"))
        soldier_model.add_child(animator)
        glb_animator = animator
        _apply_hostile_faction_look(soldier_model)

func _apply_hostile_faction_look(model: Node3D) -> void:
    # Keep the imported fabric textures while shifting the overall tone toward
    # a darker opposing woodland palette. Blue identifiers are reserved for allies.
    for item in model.find_children("*", "MeshInstance3D", true, false):
        var mesh_instance := item as MeshInstance3D
        if mesh_instance.mesh == null:
            continue
        for surface in range(mesh_instance.mesh.get_surface_count()):
            var source := mesh_instance.get_active_material(surface)
            if source is StandardMaterial3D:
                var material := source.duplicate() as StandardMaterial3D
                material.albedo_color = material.albedo_color * Color(0.92, 0.84, 0.70, 1.0)
                mesh_instance.set_surface_override_material(surface, material)

    var hostile_mark := StandardMaterial3D.new()
    hostile_mark.albedo_color = Color(0.58, 0.075, 0.035)
    hostile_mark.roughness = 0.92
    for side in [-1.0, 1.0]:
        var marker := MeshInstance3D.new()
        marker.name = "HostileRedArmIdentifier"
        var panel := BoxMesh.new()
        panel.size = Vector3(0.20, 0.12, 0.045)
        marker.mesh = panel
        marker.position = Vector3(side * 0.36, 1.36, -0.18)
        marker.material_override = hostile_mark
        model.add_child(marker)


func _rifle_assembly_part(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3, color: Color) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := BoxMesh.new()
    mesh.size = size
    part.mesh = mesh
    part.position = part_position
    part.material_override = _material(color)
    parent.add_child(part)
    return part

func _build_enemy_rifle():
    weapon_mount = Node3D.new()
    weapon_mount.name = "EnemyRifleAssembly"
    add_child(weapon_mount)

    rifle = MeshInstance3D.new()
    rifle.name = "EnemyRifleReceiver"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.10, 0.10, 0.78)
    rifle.mesh = mesh
    rifle.position = Vector3(0.0, 1.12, -0.48)
    rifle.material_override = _material(Color(0.07, 0.08, 0.07))
    weapon_mount.add_child(rifle)

    _rifle_assembly_part(weapon_mount, "RifleStock", Vector3(0.13, 0.14, 0.30), Vector3(0, 1.10, -0.06), Color(0.12, 0.14, 0.12))
    _rifle_assembly_part(weapon_mount, "RifleMagazine", Vector3(0.13, 0.30, 0.18), Vector3(0, 0.91, -0.42), Color(0.10, 0.12, 0.10))
    _rifle_assembly_part(weapon_mount, "RifleOptic", Vector3(0.14, 0.12, 0.18), Vector3(0, 1.23, -0.40), Color(0.08, 0.10, 0.10))
    _rifle_assembly_part(weapon_mount, "RifleForegrip", Vector3(0.10, 0.18, 0.12), Vector3(0, 0.99, -0.68), Color(0.11, 0.13, 0.11))
    _rifle_assembly_part(weapon_mount, "RifleBarrel", Vector3(0.045, 0.045, 0.38), Vector3(0, 1.12, -1.02), Color(0.08, 0.09, 0.08))

    muzzle_light = OmniLight3D.new()
    muzzle_light.name = "EnemyMuzzleFlash"
    muzzle_light.position = Vector3(0.0, 1.12, -1.18)
    muzzle_light.light_color = Color(1.0, 0.55, 0.18)
    muzzle_light.light_energy = 0.0
    muzzle_light.omni_range = 3.0
    weapon_mount.add_child(muzzle_light)

func _has_line_of_sight(target_position: Vector3) -> bool:
    var query := PhysicsRayQueryParameters3D.create(
        global_position + Vector3(0, 1.25, 0),
        target_position
    )
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return hit.is_empty() or hit.get("collider") == player

func _fire_at_player():
    if not is_instance_valid(player) or reload_pose_timer > 0.0 or simulated_magazine <= 0:
        return
    simulated_magazine -= 1
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

    if hit_reaction_timer > 0.0:
        hit_reaction_timer = maxf(hit_reaction_timer - delta, 0.0)
        _set_soldier_pose("hit")
    elif reload_pose_timer > 0.0:
        reload_pose_timer = maxf(reload_pose_timer - delta, 0.0)
        _set_soldier_pose("reload")
        if reload_pose_timer <= 0.0:
            simulated_magazine = 8
    elif has_cover_target and distance <= fire_range:
        _set_soldier_pose("crouch_fire")
    elif distance < 9.0:
        _set_soldier_pose("hip_fire")
    elif distance <= fire_range:
        _set_soldier_pose("aim")
    elif Vector2(velocity.x, velocity.z).length() > 0.2:
        _set_soldier_pose("move")
    else:
        _set_soldier_pose("ready")

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
        if distance <= fire_range and attack_timer <= 0.0 and reload_pose_timer <= 0.0 and simulated_magazine > 0:
            _fire_at_player()
            attack_timer = attack_cooldown
        move_and_slide()
        _animate_soldier(delta)
        if cover_hold_timer <= 0.0:
            has_cover_target = false
        return

    var squad_size := get_tree().get_nodes_in_group("enemies").size()
    flank_refresh_timer = maxf(flank_refresh_timer - delta, 0.0)
    if squad_size > 1 and flank_refresh_timer <= 0.0:
        var lateral := Vector3(-to_player.z, 0.0, to_player.x).normalized()
        var flank_side := -1.0 if squad_slot % 2 == 0 else 1.0
        flank_target = player.global_position + lateral * flank_side * 7.0 + to_player.normalized() * 4.0
        flank_refresh_timer = 4.0 + randf_range(0.0, 1.5)

    if distance > preferred_range + 2.0:
        var movement_target := player.global_position
        if squad_size > 1:
            movement_target = flank_target
        var to_target := movement_target - global_position
        to_target.y = 0.0
        var direction := to_target.normalized() if to_target.length() > 0.1 else to_player.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
    elif distance < preferred_range - 3.0:
        var retreat = -to_player.normalized()
        velocity.x = retreat.x * move_speed * 0.65
        velocity.z = retreat.z * move_speed * 0.65
    elif squad_size > 1 and distance > 7.0:
        var to_flank := flank_target - global_position
        to_flank.y = 0.0
        if to_flank.length() > 2.5:
            var flank_direction := to_flank.normalized()
            velocity.x = flank_direction.x * move_speed * 0.8
            velocity.z = flank_direction.z * move_speed * 0.8
        else:
            velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 4.0)
            velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 4.0)
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 4.0)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 4.0)

    if distance <= fire_range and attack_timer <= 0.0 and reload_pose_timer <= 0.0:
        if simulated_magazine <= 0:
            reload_pose_timer = 2.1
            _set_soldier_pose("reload")
        else:
            _fire_at_player()
        attack_timer = attack_cooldown

    move_and_slide()
    _animate_soldier(delta)


func _set_soldier_pose(next_pose: String) -> void:
    if is_instance_valid(pose_rig):
        pose_rig.set_pose(next_pose)
    if is_instance_valid(glb_animator) and glb_animator.has_method("set_combat_pose"):
        glb_animator.set_combat_pose(next_pose)

func _animate_soldier(delta: float):
    var speed := Vector2(velocity.x, velocity.z).length()
    if speed > 0.15:
        walk_cycle += delta * speed * 2.6
    else:
        walk_cycle = lerpf(walk_cycle, 0.0, minf(delta * 3.0, 1.0))
    var amount := minf(speed / maxf(move_speed, 0.01), 1.0)
    pose_rig.set_locomotion(amount, walk_cycle)

func take_damage(amount: float) -> bool:
    if is_eliminated:
        return false
    health = maxf(health - amount, 0.0)
    print("Enemy hit! Health: ", health)
    if health <= 0.0:
        die()
        return true
    hit_reaction_timer = 0.24
    if is_instance_valid(pose_rig):
        _set_soldier_pose("hit")
    _find_cover_position()
    return false

func die():
    if is_eliminated:
        return
    is_eliminated = true
    print("Enemy eliminated!")
    velocity = Vector3.ZERO
    set_physics_process(false)
    set_process(false)
    collision_layer = 0
    collision_mask = 0
    if is_instance_valid(muzzle_light):
        muzzle_light.light_energy = 0.0
    if is_instance_valid(pose_rig):
        _set_soldier_pose("death")
    var fall_tween := create_tween()
    fall_tween.set_parallel(true)
    fall_tween.tween_property(self, "rotation:z", rotation.z + deg_to_rad(82.0), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    fall_tween.tween_property(self, "position:y", maxf(position.y - 0.22, -0.22), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    fall_tween.set_parallel(false)
    fall_tween.tween_interval(4.0)
    fall_tween.tween_callback(queue_free)

