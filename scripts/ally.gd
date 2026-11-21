extends CharacterBody3D

# Friendly woodland infantry presence for the woodland outpost.
# Uses the same rigged soldier asset with a distinct cooler green tint and blue ID marks.

func _ready() -> void:
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
    animator.set_combat_pose("aim")
    _build_rifle()

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
                # Multiplying the source albedo retains its texture maps and camouflage detail.
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
    var rifle := MeshInstance3D.new()
    rifle.name = "FriendlyRifle"
    var body := BoxMesh.new()
    body.size = Vector3(0.085, 0.085, 0.72)
    rifle.mesh = body
    rifle.position = Vector3(0.0, 1.08, -0.48)
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.055, 0.065, 0.055)
    finish.roughness = 0.72
    rifle.material_override = finish
    add_child(rifle)
