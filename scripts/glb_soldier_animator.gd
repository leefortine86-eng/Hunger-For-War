extends Node3D

# Lightweight additive animation layer for the imported soldier.
# The source GLB has a rig but no animation clips, so this script adds
# locomotion and combat poses without replacing the skeleton's rest pose.

@export var walk_rate: float = 7.0
@export var walk_swing: float = 0.46
@export var run_swing: float = 0.62
@export var blend_speed: float = 8.0

var skeleton: Skeleton3D
var actor: CharacterBody3D
var phase: float = 0.0
var locomotion: float = 0.0
var movement_speed: float = 0.0
var combat_pose: String = "ready"
var bone_roles: Array[Dictionary] = []
var base_rotations: Dictionary = {}
var base_positions: Dictionary = {}
var pose_weight: float = 0.0

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
    base_rotations.clear()
    base_positions.clear()
    for i in range(skeleton.get_bone_count()):
        var bone_name := skeleton.get_bone_name(i).to_lower().replace(" ", "_").replace("-", "_")
        var role := _classify_bone(bone_name)
        if role == "":
            continue
        bone_roles.append({"index": i, "role": role, "side": _bone_side(bone_name)})
        base_rotations[i] = skeleton.get_bone_pose_rotation(i)
        base_positions[i] = skeleton.get_bone_pose_position(i)
    if bone_roles.is_empty():
        push_warning("GLB soldier animator: no supported humanoid bone names were found.")
    else:
        print("GLB soldier animator bound ", bone_roles.size(), " humanoid bones.")

func _classify_bone(name: String) -> String:
    if name.contains("thigh") or name.contains("upleg") or name.contains("upper_leg") or name.contains("hip_l") or name.contains("hip_r"):
        return "thigh"
    if name.contains("calf") or name.contains("lowerleg") or name.contains("lower_leg") or name.contains("shin"):
        return "calf"
    if name.contains("foot") or name.contains("ankle"):
        return "foot"
    if name.contains("forearm") or name.contains("lowerarm") or name.contains("lower_arm"):
        return "forearm"
    if name.contains("upperarm") or name.contains("upper_arm") or name.contains("shoulder") or name.contains("arm_l") or name.contains("arm_r"):
        return "arm"
    if name.contains("pelvis") or name == "hips" or name == "hip":
        return "pelvis"
    if name.contains("spine") or name.contains("chest"):
        return "spine"
    if name.contains("neck") or name == "head":
        return "head"
    return ""

func _bone_side(name: String) -> float:
    if name.ends_with("_l") or name.ends_with(".l") or name.contains("left"):
        return -1.0
    if name.ends_with("_r") or name.ends_with(".r") or name.contains("right"):
        return 1.0
    return 0.0

func set_combat_pose(next_pose: String) -> void:
    if next_pose in ["ready", "aim", "hip_fire", "crouch_fire", "reload", "hit", "death"]:
        combat_pose = next_pose

func _process(delta: float) -> void:
    if not is_instance_valid(skeleton):
        return
    movement_speed = 0.0
    if is_instance_valid(actor):
        movement_speed = Vector2(actor.velocity.x, actor.velocity.z).length()
    var target_locomotion := clampf(movement_speed / 3.5, 0.0, 1.0)
    locomotion = move_toward(locomotion, target_locomotion, delta * 4.5)
    if locomotion > 0.015:
        phase += delta * walk_rate * lerpf(0.65, 1.35, locomotion)
    pose_weight = move_toward(pose_weight, 1.0, delta * blend_speed)

    for item in bone_roles:
        var index: int = item.index
        var role: String = item.role
        var side: float = item.side
        var base: Quaternion = base_rotations.get(index, Quaternion.IDENTITY)
        var offset := Quaternion.IDENTITY
        var swing := sin(phase + (PI if side > 0.0 else 0.0)) * locomotion
        var speed_swing := lerpf(walk_swing, run_swing, clampf(movement_speed / 5.0, 0.0, 1.0))
        match role:
            "thigh":
                offset = Quaternion.from_euler(Vector3(swing * speed_swing, 0.0, 0.0))
            "calf":
                offset = Quaternion.from_euler(Vector3(maxf(0.0, -swing) * 0.48 * locomotion, 0.0, 0.0))
            "foot":
                offset = Quaternion.from_euler(Vector3(maxf(0.0, swing) * 0.18 * locomotion, 0.0, 0.0))
            "arm":
                var arm_motion := -swing * 0.10
                if combat_pose in ["aim", "hip_fire", "crouch_fire", "reload"]:
                    arm_motion *= 0.18
                offset = Quaternion.from_euler(Vector3(arm_motion, 0.0, side * 0.035 * locomotion))
            "forearm":
                var elbow := 0.10
                if combat_pose == "aim" or combat_pose == "hip_fire" or combat_pose == "crouch_fire":
                    elbow = 0.42
                elif combat_pose == "reload":
                    elbow = 0.58
                offset = Quaternion.from_euler(Vector3(elbow, 0.0, 0.0))
            "spine":
                var breath := sin(Time.get_ticks_msec() / 1000.0 * 1.7) * 0.012
                var lean := -0.035 if combat_pose == "aim" else 0.0
                if combat_pose == "hit":
                    lean = 0.16
                offset = Quaternion.from_euler(Vector3(lean + breath, 0.0, sin(phase * 2.0) * locomotion * 0.018))
            "pelvis":
                if combat_pose == "crouch_fire":
                    skeleton.set_bone_pose_position(index, base_positions.get(index, Vector3.ZERO) + Vector3(0.0, -0.10, 0.0))
                else:
                    skeleton.set_bone_pose_position(index, base_positions.get(index, Vector3.ZERO))
            "head":
                var head_tilt := -0.025 if combat_pose == "aim" else 0.0
                if combat_pose == "hit":
                    head_tilt = -0.12
                offset = Quaternion.from_euler(Vector3(head_tilt, 0.0, 0.0))
        if combat_pose == "death":
            if role == "spine":
                offset = Quaternion.from_euler(Vector3(0.55, 0.0, 0.0))
            elif role == "head":
                offset = Quaternion.from_euler(Vector3(-0.18, 0.0, 0.0))
        var target_rotation: Quaternion = base * offset
        var current := skeleton.get_bone_pose_rotation(index)
        skeleton.set_bone_pose_rotation(index, current.slerp(target_rotation, pose_weight))
    skeleton.force_update_all_bone_transforms()
