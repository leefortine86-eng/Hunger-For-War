extends Node3D

# Procedural Skeleton3D bridge for the prototype soldier meshes.
# Limb meshes are attached to bones; bone poses are blended in code.
# A later art pass can replace these primitives with weighted skinned meshes.

var skeleton: Skeleton3D
var pose: String = "hip_fire"
var pose_blend_speed: float = 9.0
var bone_ids: Dictionary = {}
var base_rotations: Dictionary = {}
var target_rotations: Dictionary = {}
var target_positions: Dictionary = {}
var walk_phase: float = 0.0
var move_amount: float = 0.0
var weapon_profile: String = "rifle"

func configure(soldier: Node3D, arms: Array, forearms: Array, hands: Array, legs: Array, weapon: Node3D, profile: String = "rifle") -> void:
    weapon_profile = profile
    skeleton = Skeleton3D.new()
    skeleton.name = "SoldierSkeleton"
    add_child(skeleton)
    _build_bones(soldier, arms, forearms, hands, legs)
    _attach_mesh(soldier.get_node_or_null("Body"), "spine")
    _attach_mesh(soldier.get_node_or_null("Head"), "head")
    _attach_weapon(weapon, "spine")
    for i in range(arms.size()):
        _attach_mesh(arms[i], "upper_arm_" + str(i))
    for i in range(forearms.size()):
        _attach_mesh(forearms[i], "forearm_" + str(i))
    for i in range(hands.size()):
        _attach_mesh(hands[i], "hand_" + str(i))
    for i in range(legs.size()):
        _attach_mesh(legs[i], "thigh_" + str(i))
    set_pose("hip_fire")

func _add_bone(bone_name: String, parent_name: String, local_position: Vector3) -> int:
    var index := skeleton.get_bone_count()
    skeleton.add_bone(bone_name)
    if parent_name != "":
        skeleton.set_bone_parent(index, int(bone_ids[parent_name]))
    var rest_transform := Transform3D(Basis.IDENTITY, local_position)
    skeleton.set_bone_rest(index, rest_transform)
    bone_ids[bone_name] = index
    base_rotations[bone_name] = Quaternion.IDENTITY
    return index

func _build_bones(soldier: Node3D, arms: Array, forearms: Array, hands: Array, legs: Array) -> void:
    var body: Node3D = soldier.get_node_or_null("Body")
    var head: Node3D = soldier.get_node_or_null("Head")
    _add_bone("root", "", Vector3.ZERO)
    _add_bone("pelvis", "root", Vector3(0, 0.55, 0))
    _add_bone("spine", "pelvis", Vector3(0, 0.49, 0))
    _add_bone("neck", "spine", Vector3(0, 0.54, 0))
    _add_bone("head", "neck", Vector3(0, 0.22, 0))
    for i in range(arms.size()):
        var side := -1.0 if i == 0 else 1.0
        var upper_name := "upper_arm_" + str(i)
        var fore_name := "forearm_" + str(i)
        var hand_name := "hand_" + str(i)
        var upper_pos: Vector3 = arms[i].position
        var fore_pos: Vector3 = forearms[i].position
        var hand_pos: Vector3 = hands[i].position
        _add_bone(upper_name, "spine", upper_pos - Vector3(0, 1.04, 0))
        _add_bone(fore_name, upper_name, fore_pos - upper_pos)
        _add_bone(hand_name, fore_name, hand_pos - fore_pos)
    for i in range(legs.size()):
        var leg_pos: Vector3 = legs[i].position
        _add_bone("thigh_" + str(i), "pelvis", leg_pos - Vector3(0, 0.55, 0))
    skeleton.reset_bone_poses()
    skeleton.force_update_all_bone_transforms()

func _attach_mesh(part: Node3D, bone_name: String) -> void:
    if not is_instance_valid(part) or not bone_ids.has(bone_name):
        return
    var saved_rotation := part.rotation
    var attachment := BoneAttachment3D.new()
    attachment.name = "Attach_" + bone_name
    attachment.bone_name = bone_name
    skeleton.add_child(attachment)
    var old_parent := part.get_parent()
    old_parent.remove_child(part)
    attachment.add_child(part)
    part.position = Vector3.ZERO
    part.rotation = saved_rotation

func _attach_weapon(weapon: Node3D, bone_name: String) -> void:
    if not is_instance_valid(weapon) or not bone_ids.has(bone_name):
        return
    var saved_position := weapon.position
    var saved_rotation := weapon.rotation
    var attachment := BoneAttachment3D.new()
    attachment.name = "Attach_Weapon"
    attachment.bone_name = bone_name
    skeleton.add_child(attachment)
    weapon.get_parent().remove_child(weapon)
    attachment.add_child(weapon)
    weapon.position = saved_position - Vector3(0, 1.04, 0)
    weapon.rotation = saved_rotation

func set_pose(next_pose: String) -> void:
    if next_pose not in ["move", "aim", "hip_fire", "crouch_fire", "reload", "hit"]:
        return
    pose = next_pose
    _build_pose_targets()

func set_weapon_profile(profile: String) -> void:
    weapon_profile = profile
    _build_pose_targets()

func _build_pose_targets() -> void:
    target_rotations.clear()
    target_positions.clear()
    var upper := Vector3(-0.18, 0.0, 0.24)
    var fore := Vector3(-0.20, 0.0, 0.16)
    var rifle_balance := Vector3.ZERO
    match pose:
        "aim":
            upper = Vector3(-0.34, 0.0, 0.19)
            fore = Vector3(-0.42, 0.0, 0.12)
        "hip_fire":
            upper = Vector3(-0.18, 0.0, 0.24)
            fore = Vector3(-0.20, 0.0, 0.16)
        "crouch_fire":
            upper = Vector3(-0.28, 0.0, 0.20)
            fore = Vector3(-0.36, 0.0, 0.14)
            target_positions["pelvis"] = Vector3(0, -0.16, 0)
            target_rotations["thigh_0"] = Quaternion.from_euler(Vector3(-0.38, 0, 0))
            target_rotations["thigh_1"] = Quaternion.from_euler(Vector3(0.38, 0, 0))
        "reload":
            upper = Vector3(-0.08, 0.0, 0.30)
            fore = Vector3(0.16, 0.0, 0.12)
        "hit":
            upper = Vector3(0.16, 0.0, 0.34)
            fore = Vector3(0.10, 0.0, 0.20)
            target_rotations["spine"] = Quaternion.from_euler(Vector3(0.18, 0.0, 0.0))
            target_rotations["head"] = Quaternion.from_euler(Vector3(-0.10, 0.0, 0.08))
        "move":
            upper = Vector3(-0.12, 0.0, 0.30)
            fore = Vector3(-0.12, 0.0, 0.20)
    match weapon_profile:
        "lmg":
            upper.x -= 0.07
            fore.x -= 0.08
        "launcher":
            upper.x += 0.05
        "pistol":
            upper.z -= 0.08
        "smg":
            fore.x += 0.025
    for i in range(2):
        var side := -1.0 if i == 0 else 1.0
        target_rotations["upper_arm_" + str(i)] = Quaternion.from_euler(Vector3(upper.x, upper.y, side * upper.z))
        target_rotations["forearm_" + str(i)] = Quaternion.from_euler(Vector3(fore.x, fore.y, side * fore.z))
        target_rotations["hand_" + str(i)] = Quaternion.IDENTITY
    if pose != "crouch_fire":
        target_positions["pelvis"] = Vector3.ZERO
        target_rotations["thigh_0"] = Quaternion.IDENTITY
        target_rotations["thigh_1"] = Quaternion.IDENTITY
    if pose != "hit":
        target_rotations["spine"] = Quaternion.from_euler(Vector3(-0.035 if pose == "aim" else 0.0, 0, 0))
        target_rotations["head"] = Quaternion.from_euler(Vector3(0.02 if pose == "aim" else 0.0, 0, 0))

func set_locomotion(amount: float, phase: float) -> void:
    move_amount = clampf(amount, 0.0, 1.0)
    walk_phase = phase

func _process(delta: float) -> void:
    if not is_instance_valid(skeleton):
        return
    var weight := minf(delta * pose_blend_speed, 1.0)
    for bone_name in bone_ids.keys():
        var index: int = bone_ids[bone_name]
        var target: Quaternion = target_rotations.get(bone_name, Quaternion.IDENTITY)
        if pose == "move" and str(bone_name).begins_with("thigh_"):
            var side := -1.0 if str(bone_name).ends_with("0") else 1.0
            target = Quaternion.from_euler(Vector3(sin(walk_phase) * move_amount * 0.48 * side, 0, 0))
        var current := skeleton.get_bone_pose_rotation(index)
        skeleton.set_bone_pose_rotation(index, current.slerp(target, weight))
        var target_position: Vector3 = target_positions.get(bone_name, Vector3.ZERO)
        var current_position := skeleton.get_bone_pose_position(index)
        skeleton.set_bone_pose_position(index, current_position.lerp(target_position, weight))
    skeleton.force_update_all_bone_transforms()
