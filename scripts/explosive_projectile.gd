extends Node3D

var velocity := Vector3.ZERO
var gravity_strength: float = 1.5
var fuse_remaining: float = 8.0
var blast_radius: float = 6.0
var blast_damage: float = 150.0
var direct_damage: float = 150.0
var shooter: Node3D
var world_root: Node
var projectile_kind: String = "rocket"
var exploded: bool = false
var visual: MeshInstance3D
var trail_light: OmniLight3D

func configure(origin: Vector3, direction: Vector3, speed: float, gravity_value: float, fuse: float, radius: float, damage_value: float, kind: String, owner_node: Node3D, world: Node) -> void:
    global_position = origin
    velocity = direction.normalized() * speed
    gravity_strength = gravity_value
    fuse_remaining = fuse
    blast_radius = radius
    blast_damage = damage_value
    direct_damage = damage_value
    projectile_kind = kind
    shooter = owner_node
    world_root = world
    _build_visual()

func _build_visual() -> void:
    visual = MeshInstance3D.new()
    visual.name = "ProjectileVisual"
    if projectile_kind == "grenade":
        var sphere := SphereMesh.new()
        sphere.radius = 0.09
        sphere.height = 0.18
        visual.mesh = sphere
    else:
        var capsule := CylinderMesh.new()
        capsule.top_radius = 0.055
        capsule.bottom_radius = 0.055
        capsule.height = 0.42
        visual.mesh = capsule
        visual.rotation.x = PI / 2.0
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.22, 0.24, 0.19) if projectile_kind == "rocket" else Color(0.16, 0.17, 0.15)
    material.metallic = 0.45
    material.roughness = 0.42
    visual.material_override = material
    add_child(visual)

    trail_light = OmniLight3D.new()
    trail_light.light_color = Color(1.0, 0.42, 0.12)
    trail_light.light_energy = 0.7 if projectile_kind == "rocket" else 0.12
    trail_light.omni_range = 2.2
    add_child(trail_light)

func _physics_process(delta: float) -> void:
    if exploded:
        return
    fuse_remaining -= delta
    if fuse_remaining <= 0.0:
        _explode(global_position)
        return

    var previous_position := global_position
    velocity.y -= gravity_strength * delta
    var next_position := previous_position + velocity * delta
    var query := PhysicsRayQueryParameters3D.create(previous_position, next_position)
    query.collide_with_areas = true
    query.collide_with_bodies = true
    if is_instance_valid(shooter):
        query.exclude = [shooter.get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    global_position = next_position
    if velocity.length_squared() > 0.01:
        look_at(global_position + velocity.normalized(), Vector3.UP)
    if not hit.is_empty():
        var collider = hit.get("collider")
        if is_instance_valid(collider) and collider.has_method("take_damage"):
            collider.take_damage(direct_damage)
        _explode(hit.get("position", global_position))

func _explode(point: Vector3) -> void:
    if exploded:
        return
    exploded = true
    global_position = point
    _apply_blast_damage(point)
    _spawn_blast_visual(point)
    queue_free()

func _apply_blast_damage(point: Vector3) -> void:
    var shape := SphereShape3D.new()
    shape.radius = blast_radius
    var params := PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis.IDENTITY, point)
    params.collide_with_areas = true
    params.collide_with_bodies = true
    if is_instance_valid(shooter):
        params.exclude = [shooter.get_rid()]
    var hits := get_world_3d().direct_space_state.intersect_shape(params, 64)
    var damaged := {}
    for hit in hits:
        var target = hit.get("collider")
        if not is_instance_valid(target) or not target.has_method("take_damage"):
            continue
        var instance_id := target.get_instance_id()
        if damaged.has(instance_id):
            continue
        damaged[instance_id] = true
        var distance := point.distance_to(target.global_position)
        var falloff := clampf(1.0 - distance / blast_radius, 0.18, 1.0)
        target.take_damage(blast_damage * falloff)

func _spawn_blast_visual(point: Vector3) -> void:
    if not is_instance_valid(world_root):
        return
    var blast := MeshInstance3D.new()
    blast.name = "ExplosionFlash"
    var sphere := SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 2.0
    blast.mesh = sphere
    var material := StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color(1.0, 0.48, 0.12, 0.72)
    material.emission_enabled = true
    material.emission = Color(1.0, 0.22, 0.04)
    material.emission_energy_multiplier = 2.5
    blast.material_override = material
    world_root.add_child(blast)
    blast.global_position = point
    blast.scale = Vector3.ONE * 0.18
    var tween := blast.create_tween()
    tween.tween_property(blast, "scale", Vector3.ONE * blast_radius, 0.24)
    tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.24)
    tween.tween_callback(blast.queue_free)
