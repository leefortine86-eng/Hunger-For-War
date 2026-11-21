extends CharacterBody3D

# Friendly infantry maneuver, seek cover/angles, and provide supporting fire.
# The player remains in control; allies behave as independent battlefield AI.

@export var engagement_range: float = 38.0
@export var preferred_range: float = 19.0
@export var move_speed: float = 2.8
@export var damage_per_shot: float = 11.0
@export var shot_interval: float = 1.05
@export var aim_height: float = 1.05

var target: CharacterBody3D
var shot_timer: float = 0.6
var shot_pose_remaining: float = 0.0
var muzzle_flash_timer: float = 0.0
var muzzle_light: OmniLight3D
var soldier_animator: Node
var weapon_mount: Node3D
var gravity: float = 20.0
var squad_slot: int = 0
var maneuver_timer: float = 0.0
var maneuver_target: Vector3 = Vector3.ZERO

func _ready() -> void:
    add_to_group("allies")
    squad_slot = get_tree().get_nodes_in_group("allies").size() - 1
    _build_character()
    _build_rifle()
    _build_muzzle_light()
    if is_instance_valid(soldier_animator) and soldier_animator.has_method("attach_weapon_to_hand"):
        soldier_animator.attach_weapon_to_hand(weapon_mount)
    set_physics_process(true)

func _build_character() -> void:
    var soldier_scene := load("res://assets/characters/Military_Male_03.glb") as PackedScene
    if soldier_scene == null:
        push_warning("Friendly soldier: imported GLB could not be loaded.")
        return
    var model := soldier_scene.instantiate()
    model.name = "FriendlyWoodlandSoldier"
    add_child(model)
    _tint_model(model)
    _add_friendly_identification(model)
    var animator := Node3D.new()
    animator.name = "GLBSoldierAnimator"
    animator.set_script(load("res://scripts/glb_soldier_animator.gd"))
    model.add_child(animator)
    soldier_animator = animator
    animator.set_combat_pose("aim")

func _tint_model(model: Node) -> void:
    var meshes := model.find_children("*", "MeshInstance3D", true, false)
    for item in meshes:
        var mesh_instance := item as MeshInstance3D
        if mesh_instance.mesh == null:
            continue
        for surface in range(mesh_instance.mesh.get_surface_count()):
            var source := mesh_instance.get_active_material(surface)
            if source is StandardMaterial3D:
                var material := source.duplicate() as StandardMaterial3D
                material.albedo_color = material.albedo_color * Color(0.78, 1.0, 0.76, 1.0)
                mesh_instance.set_surface_override_material(surface, material)

func _add_friendly_identification(model: Node3D) -> void:
    var blue := StandardMaterial3D.new()
    blue.albedo_color = Color(0.035, 0.22, 0.62)
    blue.roughness = 0.9
    for side in [-1.0, 1.0]:
        var marker := MeshInstance3D.new()
        marker.name = "FriendlyBlueArmIdentifier"
        var panel := BoxMesh.new()
        panel.size = Vector3(0.20, 0.12, 0.045)
        marker.mesh = panel
        marker.position = Vector3(side * 0.36, 1.36, -0.18)
        marker.material_override = blue
        model.add_child(marker)

func _rifle_part(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3, material: Material) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = part_name
    var mesh := BoxMesh.new()
    mesh.size = size
    part.mesh = mesh
    part.position = part_position
    part.material_override = material
    parent.add_child(part)
    return part

func _build_rifle() -> void:
    weapon_mount = Node3D.new()
    weapon_mount.name = "FriendlyRifleAssembly"
    add_child(weapon_mount)
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.055, 0.065, 0.055)
    finish.roughness = 0.78
    var polymer := StandardMaterial3D.new()
    polymer.albedo_color = Color(0.12, 0.14, 0.12)
    polymer.roughness = 0.86
    _rifle_part(weapon_mount, "RifleReceiver", Vector3(0.085, 0.085, 0.72), Vector3(0.0, 1.10, -0.48), finish)
    _rifle_part(weapon_mount, "RifleStock", Vector3(0.12, 0.12, 0.24), Vector3(0.0, 1.10, -0.10), polymer)
    _rifle_part(weapon_mount, "RifleMagazine", Vector3(0.11, 0.25, 0.14), Vector3(0.0, 0.92, -0.40), finish)
    _rifle_part(weapon_mount, "RifleOptic", Vector3(0.12, 0.10, 0.15), Vector3(0.0, 1.20, -0.40), polymer)
    _rifle_part(weapon_mount, "RifleForegrip", Vector3(0.075, 0.16, 0.09), Vector3(0.0, 0.98, -0.70), polymer)
    _rifle_part(weapon_mount, "RifleBarrel", Vector3(0.045, 0.045, 0.38), Vector3(0.0, 1.10, -1.00), finish)

func _build_muzzle_light() -> void:
    muzzle_light = OmniLight3D.new()
    muzzle_light.name = "FriendlyMuzzleFlash"
    muzzle_light.position = Vector3(0.0, 1.10, -1.18)
    muzzle_light.light_color = Color(1.0, 0.62, 0.25)
    muzzle_light.light_energy = 0.0
    muzzle_light.omni_range = 3.0
    weapon_mount.add_child(muzzle_light)

func _find_target() -> CharacterBody3D:
    var best: CharacterBody3D
    var best_distance := engagement_range
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate) or not candidate is CharacterBody3D:
            continue
        if candidate.get("is_eliminated") == true:
            continue
        var distance := global_position.distance_to(candidate.global_position)
        if distance < best_distance:
            best_distance = distance
            best = candidate as CharacterBody3D
    return best

func _has_line_of_sight(enemy: CharacterBody3D) -> bool:
    var from := global_position + Vector3(0.0, aim_height, 0.0)
    var to := enemy.global_position + Vector3(0.0, aim_height, 0.0)
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return not hit.is_empty() and hit.get("collider") == enemy

func _choose_maneuver_position() -> void:
    if not is_instance_valid(target):
        return
    var away_from_target := global_position - target.global_position
    away_from_target.y = 0.0
    if away_from_target.length() < 0.1:
        away_from_target = Vector3.FORWARD
    var radial := away_from_target.normalized()
    var lateral := Vector3(-radial.z, 0.0, radial.x)
    var side := -1.0 if squad_slot % 2 == 0 else 1.0
    var spacing := 2.6 + (float(squad_slot) / 2.0) * 1.1
    maneuver_target = target.global_position + radial * preferred_range + lateral * side * spacing
    maneuver_timer = 3.5 + randf_range(0.0, 1.2)

func _fire_at_target() -> void:
    if not is_instance_valid(target):
        return
    if target.has_method("take_damage"):
        target.take_damage(damage_per_shot)
    if is_instance_valid(muzzle_light):
        muzzle_light.light_energy = 2.4
        muzzle_flash_timer = 0.055
    shot_pose_remaining = 0.16
    if is_instance_valid(soldier_animator):
        soldier_animator.set_combat_pose("hip_fire")
    shot_timer = shot_interval

func _physics_process(delta: float) -> void:
    shot_timer = maxf(shot_timer - delta, 0.0)
    shot_pose_remaining = maxf(shot_pose_remaining - delta, 0.0)
    maneuver_timer = maxf(maneuver_timer - delta, 0.0)
    if muzzle_flash_timer > 0.0:
        muzzle_flash_timer -= delta
        if muzzle_flash_timer <= 0.0 and is_instance_valid(muzzle_light):
            muzzle_light.light_energy = 0.0

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    if not is_instance_valid(target) or target.get("is_eliminated") == true:
        target = _find_target()
        maneuver_timer = 0.0

    velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 4.0)
    velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 4.0)

    if is_instance_valid(target):
        var to_target := target.global_position - global_position
        to_target.y = 0.0
        var distance := to_target.length()
        if distance <= engagement_range:
            look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
            if maneuver_timer <= 0.0:
                _choose_maneuver_position()
            var to_maneuver := maneuver_target - global_position
            to_maneuver.y = 0.0
            if to_maneuver.length() > 1.4:
                var direction := to_maneuver.normalized()
                velocity.x = direction.x * move_speed
                velocity.z = direction.z * move_speed
            if is_instance_valid(soldier_animator) and shot_pose_remaining <= 0.0:
                soldier_animator.set_combat_pose("aim")
            if distance <= engagement_range and shot_timer <= 0.0 and _has_line_of_sight(target):
                _fire_at_target()
        else:
            target = null
    elif is_instance_valid(soldier_animator):
        soldier_animator.set_combat_pose("ready")

    move_and_slide()
