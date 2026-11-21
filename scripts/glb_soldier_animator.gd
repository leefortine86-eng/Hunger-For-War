extends Node3D

# Lightweight procedural animation and hand-mounted weapon support for the
# imported rig. The source GLB has a skeleton but no authored animation clips.

@export var walk_rate: float = 7.0
@export var walk_swing: float = 0.42
@export var run_swing: float = 0.66
@export var blend_speed: float = 9.0
@export var crouch_depth: float = 0.20

var skeleton: Skeleton3D
var actor: CharacterBody3D
var phase: float = 0.0
var locomotion: float = 0.0
var movement_speed: float = 0.0
var combat_pose: String = "ready"
var bone_roles: Array[Dictionary] = []
var base_rotations: Dictionary = {}
var base_positions: Dictionary = {}
var recoil_time: float = 0.0
var idle_breath_time: float = 0.0
var pose_blend: float = 0.0
var pending_weapon: Node3D
var weapon_attachment: BoneAttachment3D
var right_hand_bone: String = ""
var left_hand_bone: String = ""

func _ready() -> void:
    actor = get_parent().get_parent() as CharacterBody3D
    call_deferred("_bind_skeleton")

func _bind_skeleton() -> void:
    var model := get_parent()
    if model == null:
        return
    var found := model.find_children("*", "Skeleton3D", true, false)
    if found.is_empty():
        push_warning("GLB soldier animator: no Skeleton3D found.")
        return
    skeleton = found[0] as Skeleton3D
    bone_roles.clear()
    base_rotations.clear()
    base_positions.clear()
    right_hand_bone = ""
    left_hand_bone = ""
    for i in range(skeleton.get_bone_count()):
        var original_name := skeleton.get_bone_name(i)
        var bone_name := original_name.to_lower().replace(" ", "_").replace("-", "_")
        var role := _classify_bone(bone_name)
        if role != "":
            bone_roles.append({"index": i, "role": role, "side": _bone_side(bone_name)})
            base_rotations[i] = skeleton.get_bone_pose_rotation(i)
            base_positions[i] = skeleton.get_bone_pose_position(i)
        if _is_right_hand(bone_name):
            right_hand_bone = original_name
        elif _is_left_hand(bone_name):
            left_hand_bone = original_name
    if bone_roles.is_empty():
        push_warning("GLB soldier animator: no supported humanoid bone names found.")
    else:
        print("GLB soldier animator bound ", bone_roles.size(), " bones; right hand=", right_hand_bone, " left hand=", left_hand_bone)
    if is_instance_valid(pending_weapon):
        _attach_weapon_now(pending_weapon)

func _classify_bone(name: String) -> String:
    if name.contains("thigh") or name.contains("upleg") or name.contains("upper_leg"):
        return "thigh"
    if name.contains("calf") or name.contains("lowerleg") or name.contains("lower_leg") or name.contains("shin"):
        return "calf"
    if name.contains("foot") or name.contains("ankle"):
        return "foot"
    if name.contains("forearm") or name.contains("lowerarm") or name.contains("lower_arm"):
        return "forearm"
    if name.contains("upperarm") or name.contains("upper_arm") or name.contains("shoulder") or name.contains("arm_l") or name.contains("arm_r") or name.contains("leftarm") or name.contains("rightarm"):
        return "arm"
    if name.contains("hand"):
        return "hand"
    if name.contains("pelvis") or name == "hips" or name == "hip":
        return "pelvis"
    if name.contains("spine") or name.contains("chest"):
        return "spine"
    if name.contains("neck") or name == "head":
        return "head"
    return ""

func _bone_side(name: String) -> float:
    # Support both descriptive names (LeftArm) and common Bip01_L_Arm rigs.
    if name.contains("left") or name.contains("_l_") or name.ends_with("_l") or name.ends_with(".l"):
        return -1.0
    if name.contains("right") or name.contains("_r_") or name.ends_with("_r") or name.ends_with(".r"):
        return 1.0
    return 0.0

func _is_right_hand(name: String) -> bool:
    return name.contains("righthand") or name.contains("right_hand") or name.contains("_r_hand") or name.ends_with("hand_r") or name.ends_with("hand.r") or name == "hand.r"

func _is_left_hand(name: String) -> bool:
    return name.contains("lefthand") or name.contains("left_hand") or name.contains("_l_hand") or name.ends_with("hand_l") or name.ends_with("hand.l") or name == "hand.l"

func attach_weapon_to_hand(weapon: Node3D) -> void:
    if not is_instance_valid(weapon):
        return
    pending_weapon = weapon
    if is_instance_valid(skeleton):
        _attach_weapon_now(weapon)

func _attach_weapon_now(weapon: Node3D) -> void:
    if not is_instance_valid(skeleton) or not is_instance_valid(weapon):
        return
    if right_hand_bone == "":
        push_warning("GLB soldier: no recognized right-hand bone; keeping weapon on its authored mount.")
        return
    var saved_transform := weapon.global_transform
    if is_instance_valid(weapon_attachment):
        weapon_attachment.queue_free()
    weapon_attachment = BoneAttachment3D.new()
    weapon_attachment.name = "RightHandWeaponAttachment"
    weapon_attachment.bone_name = right_hand_bone
    skeleton.add_child(weapon_attachment)
    var old_parent := weapon.get_parent()
    if old_parent != null:
        old_parent.remove_child(weapon)
    weapon_attachment.add_child(weapon)
    weapon.global_transform = saved_transform
    weapon.name = "HandMountedRifle"
    pending_weapon = null
    print("GLB soldier rifle attached to ", right_hand_bone, ". Left-hand support pose is procedural.")

func set_combat_pose(next_pose: String) -> void:
    if next_pose in ["ready", "aim", "hip_fire", "crouch_fire", "reload", "hit", "death", "move"]:
        combat_pose = next_pose
        if next_pose in ["hip_fire", "crouch_fire"]:
            recoil_time = 0.14
        pose_blend = 0.0

func _process(delta: float) -> void:
    if not is_instance_valid(skeleton):
        return
    movement_speed = 0.0
    if is_instance_valid(actor):
        movement_speed = Vector2(actor.velocity.x, actor.velocity.z).length()
    var target_locomotion := clampf(movement_speed / 4.4, 0.0, 1.0)
    locomotion = move_toward(locomotion, target_locomotion, delta * 5.5)
    if locomotion > 0.01:
        phase += delta * walk_rate * lerpf(0.72, 1.48, locomotion)
    idle_breath_time += delta
    recoil_time = maxf(recoil_time - delta, 0.0)
    pose_blend = minf(pose_blend + delta * blend_speed, 1.0)

    var aiming := combat_pose in ["aim", "hip_fire", "crouch_fire"]
    var crouched := combat_pose == "crouch_fire"
    var reloading := combat_pose == "reload"
    var hit := combat_pose == "hit"
    var dead := combat_pose == "death"
    var running := clampf((movement_speed - 2.5) / 2.5, 0.0, 1.0)
    var swing_size := lerpf(walk_swing, run_swing, running)
    var breath := sin(idle_breath_time * 1.6) * 0.009

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
                var knee := maxf(0.0, -swing) * (0.34 + running * 0.18) * locomotion
                offset = Quaternion.from_euler(Vector3(knee, 0.0, 0.0))
            "foot":
                offset = Quaternion.from_euler(Vector3(maxf(0.0, swing) * 0.16 * locomotion, 0.0, 0.0))
            "arm":
                var shoulder_pitch := -0.12 if aiming else -0.035
                var shoulder_roll := side * 0.045
                if reloading:
                    shoulder_pitch = -0.04
                if dead:
                    shoulder_pitch = 0.55
                # Keep the rifle-bearing arms stable during locomotion; swinging them
                # independently makes the weapon float away from the hands.
                offset = Quaternion.from_euler(Vector3(shoulder_pitch, 0.0, shoulder_roll))
            "forearm":
                # Both elbows tuck inward to support the rifle; the left forearm
                # reaches farther toward the handguard than the firing arm.
                var elbow := 0.28 if aiming else 0.12
                if side < 0.0 and aiming:
                    elbow = 0.46
                if reloading:
                    elbow = 0.62
                if hit:
                    elbow = -0.12
                if dead:
                    elbow = 0.75
                offset = Quaternion.from_euler(Vector3(elbow + recoil_time * 0.55, 0.0, side * (0.035 if aiming else 0.0)))
            "hand":
                var wrist := -0.04 if aiming else 0.0
                if reloading:
                    wrist = 0.28
                offset = Quaternion.from_euler(Vector3(wrist, 0.0, side * 0.025))
            "pelvis":
                position_offset.y = -crouch_depth if crouched else 0.0
                offset = Quaternion.from_euler(Vector3(0.0, 0.0, sin(phase * 2.0) * locomotion * 0.014))
            "spine":
                var lean := -0.045 if aiming else 0.0
                if hit:
                    lean = 0.16
                if dead:
                    lean = 0.68
                offset = Quaternion.from_euler(Vector3(lean + breath + recoil_time * 0.24, 0.0, sin(phase * 2.0) * locomotion * 0.018))
            "head":
                var tilt := -0.025 if aiming else 0.0
                if hit:
                    tilt = -0.13
                if dead:
                    tilt = -0.28
                offset = Quaternion.from_euler(Vector3(tilt, 0.0, 0.0))

        var target_rotation: Quaternion = base * offset
        var current := skeleton.get_bone_pose_rotation(index)
        skeleton.set_bone_pose_rotation(index, current.slerp(target_rotation, minf(delta * blend_speed, 1.0)))
        var base_position: Vector3 = base_positions.get(index, Vector3.ZERO)
        var target_position: Vector3 = base_position + position_offset
        var current_position := skeleton.get_bone_pose_position(index)
        skeleton.set_bone_pose_position(index, current_position.lerp(target_position, minf(delta * blend_speed, 1.0)))
    skeleton.force_update_all_bone_transforms()
