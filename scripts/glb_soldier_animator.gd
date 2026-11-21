extends Node3D

# Additive animation layer for the imported, rigged soldier.
# The source GLB contains a skeleton but no animation clips. This controller
# preserves the imported rest pose and layers lightweight combat/locomotion motion.

@export var walk_rate: float = 7.0
@export var walk_swing: float = 0.48
@export var run_swing: float = 0.68
@export var blend_speed: float = 7.5
@export var crouch_depth: float = 0.22

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
var recoil_time: float = 0.0
var idle_breath_time: float = 0.0

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
    if name.contains("upperarm") or name.contains("upper_arm") or name.contains("leftarm") or name.contains("rightarm") or name.contains("shoulder") or name.contains("arm_l") or name.contains("arm_r"):
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
    if next_pose in ["ready", "aim", "hip_fire", "crouch_fire", "reload", "hit", "death", "move"]:
        combat_pose = next_pose
        if next_pose == "hip_fire" or next_pose == "crouch_fire":
            recoil_time = 0.13

func _process(delta: float) -> void:
    if not is_instance_valid(skeleton):
        return
    movement_speed = 0.0
    if is_instance_valid(actor):
        movement_speed = Vector2(actor.velocity.x, actor.velocity.z).length()
    var target_locomotion := clampf(movement_speed / 4.4, 0.0, 1.0)
    locomotion = move_toward(locomotion, target_locomotion, delta * 5.5)
    if locomotion > 0.012:
        phase += delta * walk_rate * lerpf(0.72, 1.48, locomotion)
    idle_breath_time += delta
    recoil_time = maxf(recoil_time - delta, 0.0)
    pose_weight = move_toward(pose_weight, 1.0, delta * blend_speed)

    var is_aiming := combat_pose in ["aim", "hip_fire", "crouch_fire"]
    var is_crouched := combat_pose == "crouch_fire"
    var is_reloading := combat_pose == "reload"
    var is_hit := combat_pose == "hit"
    var is_dead := combat_pose == "death"
    var run_blend := clampf((movement_speed - 2.5) / 2.5, 0.0, 1.0)
    var swing_size := lerpf(walk_swing, run_swing, run_blend)
    var breath := sin(idle_breath_time * 1.65) * 0.012

    for item in bone_roles:
        var index: int = item.index
        var role: String = item.role
        var side: float = item.side
        var base: Quaternion = base_rotations.get(index, Quaternion.IDENTITY)
        var offset := Quaternion.IDENTITY
        var position_offset := Vector3.ZERO
        var swing := sin(phase + (PI if side > 0.0 else 0.0)) * locomotion

        match role:
            "thigh":
                offset = Quaternion.from_euler(Vector3(swing * swing_size, 0.0, 0.0))
            "calf":
                var knee_lift := maxf(0.0, -swing) * (0.42 + run_blend * 0.20) * locomotion
                offset = Quaternion.from_euler(Vector3(knee_lift, 0.0, 0.0))
            "foot":
                offset = Quaternion.from_euler(Vector3(maxf(0.0, swing) * 0.20 * locomotion, 0.0, 0.0))
            "arm":
                var arm_swing := -swing * 0.22
                if is_aiming or is_reloading:
                    arm_swing *= 0.12
                var ready_raise := -0.20 if is_aiming else -0.08
                if is_reloading:
                    ready_raise = -0.02
                offset = Quaternion.from_euler(Vector3(ready_raise + arm_swing, 0.0, side * (0.045 * locomotion)))
            "forearm":
                var elbow := 0.16
                if is_aiming:
                    elbow = 0.48
                elif is_reloading:
                    elbow = 0.64
                offset = Quaternion.from_euler(Vector3(elbow + recoil_time * 0.65, 0.0, side * (0.025 if is_aiming else 0.0)))
            "pelvis":
                position_offset.y = -crouch_depth if is_crouched else 0.0
                offset = Quaternion.from_euler(Vector3(0.0, 0.0, sin(phase * 2.0) * locomotion * 0.018))
            "spine":
                var lean := -0.055 if is_aiming else 0.0
                if is_hit:
                    lean = 0.18
                if is_dead:
                    lean = 0.72
                offset = Quaternion.from_euler(Vector3(lean + breath + recoil_time * 0.32, 0.0, sin(phase * 2.0) * locomotion * 0.025))
            "head":
                var head_tilt := -0.035 if is_aiming else 0.0
                if is_hit:
                    head_tilt = -0.16
                if is_dead:
                    head_tilt = -0.30
                offset = Quaternion.from_euler(Vector3(head_tilt, 0.0, 0.0))

        var target_rotation: Quaternion = base * offset
        var current := skeleton.get_bone_pose_rotation(index)
        skeleton.set_bone_pose_rotation(index, current.slerp(target_rotation, minf(delta * blend_speed, 1.0)))
        var base_position: Vector3 = base_positions.get(index, Vector3.ZERO)
        var target_position: Vector3 = base_position + position_offset
        var current_position := skeleton.get_bone_pose_position(index)
        skeleton.set_bone_pose_position(index, current_position.lerp(target_position, minf(delta * blend_speed, 1.0)))
    skeleton.force_update_all_bone_transforms()
