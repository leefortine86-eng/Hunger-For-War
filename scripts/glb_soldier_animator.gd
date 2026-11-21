extends Node3D

# Lightweight procedural animation for the imported GLB when it has no clips.
# Uses common Mixamo-style bone names and safely skips bones it cannot identify.

@export var walk_rate: float = 7.0
@export var walk_swing: float = 0.42
@export var arm_swing: float = 0.16

var skeleton: Skeleton3D
var actor: CharacterBody3D
var phase: float = 0.0
var intensity: float = 0.0
var bone_roles: Array[Dictionary] = []

func _ready() -> void:
    actor = get_parent().get_parent() as CharacterBody3D
    call_deferred("_bind_skeleton")

func _bind_skeleton() -> void:
    var model := get_parent()
    if model == null:
        return
    var found := model.find_children("*", "Skeleton3D", true, false)
    if found.is_empty():
        push_warning("GLB soldier animator: no Skeleton3D found in imported model.")
        return
    skeleton = found[0] as Skeleton3D
    bone_roles.clear()
    for i in range(skeleton.get_bone_count()):
        var bone_name := skeleton.get_bone_name(i).to_lower().replace(" ", "_")
        var role := ""
        if bone_name.contains("thigh") or bone_name.contains("upleg") or bone_name.contains("upper_leg"):
            role = "thigh"
        elif bone_name.contains("calf") or bone_name.contains("lowerleg") or bone_name.contains("lower_leg") or bone_name.contains("shin"):
            role = "calf"
        elif bone_name.contains("forearm") or bone_name.contains("lowerarm") or bone_name.contains("lower_arm"):
            role = "forearm"
        elif bone_name.contains("upperarm") or bone_name.contains("upper_arm") or bone_name.contains("arm"):
            role = "arm"
        elif bone_name.contains("spine") or bone_name.contains("chest"):
            role = "spine"
        elif bone_name.contains("neck") or bone_name.contains("head"):
            role = "head"
        if role != "":
            bone_roles.append({"index": i, "role": role, "side": _bone_side(bone_name)})
    if bone_roles.is_empty():
        push_warning("GLB soldier animator: skeleton bone names did not match supported humanoid names.")

func _bone_side(name: String) -> float:
    if name.ends_with("_l") or name.ends_with(".l") or name.contains("left"):
        return -1.0
    if name.ends_with("_r") or name.ends_with(".r") or name.contains("right"):
        return 1.0
    return 0.0

func _process(delta: float) -> void:
    if not is_instance_valid(skeleton):
        return
    var speed := 0.0
    if is_instance_valid(actor):
        speed = Vector2(actor.velocity.x, actor.velocity.z).length()
    var target_intensity := clampf(speed / 3.0, 0.0, 1.0)
    intensity = move_toward(intensity, target_intensity, delta * 5.0)
    if intensity > 0.01:
        phase += delta * walk_rate * lerpf(0.55, 1.45, intensity)
    for item in bone_roles:
        var index: int = item.index
        var role: String = item.role
        var side: float = item.side
        var swing := sin(phase + (PI if side > 0.0 else 0.0)) * intensity
        var rotation := Quaternion.IDENTITY
        match role:
            "thigh":
                rotation = Quaternion.from_euler(Vector3(swing * walk_swing, 0.0, 0.0))
            "calf":
                rotation = Quaternion.from_euler(Vector3(maxf(0.0, -swing) * walk_swing * 0.7, 0.0, 0.0))
            "arm":
                rotation = Quaternion.from_euler(Vector3(-swing * arm_swing, 0.0, 0.0))
            "forearm":
                rotation = Quaternion.from_euler(Vector3(0.12, 0.0, 0.0))
            "spine":
                rotation = Quaternion.from_euler(Vector3(0.0, 0.0, sin(phase * 2.0) * intensity * 0.025))
            "head":
                rotation = Quaternion.from_euler(Vector3(0.0, 0.0, 0.0))
        skeleton.set_bone_pose_rotation(index, rotation)
