extends CharacterBody3D

# Friendly woodland infantry. Allies hold position, acquire hostile AI soldiers,
# check line of sight, and provide measured supporting fire.

@export var engagement_range: float = 34.0
@export var damage_per_shot: float = 11.0
@export var shot_interval: float = 1.05
@export var aim_height: float = 1.05

var target: CharacterBody3D
var shot_timer: float = 0.6
var muzzle_flash_timer: float = 0.0
var muzzle_light: OmniLight3D
var soldier_animator: Node

func _ready() -> void:
    add_to_group("allies")
    _build_character()
    _build_rifle()
    _build_muzzle_light()
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

func _build_rifle() -> void:
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.055, 0.065, 0.055)
    finish.roughness = 0.78

    var rifle := MeshInstance3D.new()
    rifle.name = "FriendlyRifle"
    var body := BoxMesh.new()
    body.size = Vector3(0.085, 0.085, 0.72)
    rifle.mesh = body
    rifle.position = Vector3(0.0, 1.10, -0.48)
    rifle.material_override = finish
    add_child(rifle)

    var stock := MeshInstance3D.new()
    stock.name = "RifleStock"
    var stock_mesh := BoxMesh.new()
    stock_mesh.size = Vector3(0.12, 0.12, 0.24)
    stock.mesh = stock_mesh
    stock.position = Vector3(0.0, 1.10, -0.10)
    stock.material_override = finish
    add_child(stock)

    var magazine := MeshInstance3D.new()
    magazine.name = "RifleMagazine"
    var magazine_mesh := BoxMesh.new()
    magazine_mesh.size = Vector3(0.11, 0.25, 0.14)
    magazine.mesh = magazine_mesh
    magazine.position = Vector3(0.0, 0.92, -0.40)
    magazine.material_override = finish
    add_child(magazine)

    var optic := MeshInstance3D.new()
    optic.name = "RifleOptic"
    var optic_mesh := BoxMesh.new()
    optic_mesh.size = Vector3(0.12, 0.10, 0.15)
    optic.mesh = optic_mesh
    optic.position = Vector3(0.0, 1.20, -0.40)
    optic.material_override = finish
    add_child(optic)

func _build_muzzle_light() -> void:
    muzzle_light = OmniLight3D.new()
    muzzle_light.name = "FriendlyMuzzleFlash"
    muzzle_light.position = Vector3(0.0, 1.10, -0.92)
    muzzle_light.light_color = Color(1.0, 0.62, 0.25)
    muzzle_light.light_energy = 0.0
    muzzle_light.omni_range = 3.0
    add_child(muzzle_light)

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

func _fire_at_target() -> void:
    if not is_instance_valid(target):
        return
    if target.has_method("take_damage"):
        target.take_damage(damage_per_shot)
    if is_instance_valid(muzzle_light):
        muzzle_light.light_energy = 2.4
        muzzle_flash_timer = 0.055
    shot_timer = shot_interval

func _physics_process(delta: float) -> void:
    shot_timer = maxf(shot_timer - delta, 0.0)
    if muzzle_flash_timer > 0.0:
        muzzle_flash_timer -= delta
        if muzzle_flash_timer <= 0.0 and is_instance_valid(muzzle_light):
            muzzle_light.light_energy = 0.0

    velocity = Vector3.ZERO
    if not is_instance_valid(target) or target.get("is_eliminated") == true:
        target = _find_target()

    if not is_instance_valid(target):
        if is_instance_valid(soldier_animator):
            soldier_animator.set_combat_pose("ready")
        return

    var distance := global_position.distance_to(target.global_position)
    if distance > engagement_range:
        target = null
        return

    look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
    if is_instance_valid(soldier_animator):
        soldier_animator.set_combat_pose("aim")

    if shot_timer <= 0.0 and _has_line_of_sight(target):
        _fire_at_target()
