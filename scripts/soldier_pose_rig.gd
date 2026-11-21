extends Node

# Lightweight articulated pose rig for the current procedural soldier meshes.
# Each limb is independently driven and blended; this is a bridge toward a
# full Skeleton3D/AnimationTree character asset, not a replacement for one.

var upper_arms: Array[Node3D] = []
var forearms: Array[Node3D] = []
var hands: Array[Node3D] = []
var legs: Array[Node3D] = []
var rifle: Node3D
var torso: Node3D
var head: Node3D
var pose: String = "hip_fire"
var weapon_profile: String = "rifle"
var blend_speed: float = 8.0
var rest: Dictionary = {}
var targets: Dictionary = {}

func configure(arms: Array, lower_arms: Array, grip_hands: Array, soldier_legs: Array, weapon: Node3D, body: Node3D = null, helmet_head: Node3D = null, profile: String = "rifle") -> void:
    upper_arms.assign(arms)
    forearms.assign(lower_arms)
    hands.assign(grip_hands)
    legs.assign(soldier_legs)
    rifle = weapon
    torso = body
    head = helmet_head
    weapon_profile = profile
    _remember(upper_arms, "arms")
    _remember(forearms, "forearms")
    _remember(hands, "hands")
    _remember(legs, "legs")
    if is_instance_valid(rifle):
        rest["rifle_position"] = rifle.position
        rest["rifle_rotation"] = rifle.rotation
    if is_instance_valid(torso):
        rest["torso_position"] = torso.position
        rest["torso_rotation"] = torso.rotation
    if is_instance_valid(head):
        rest["head_position"] = head.position
        rest["head_rotation"] = head.rotation
    set_pose("hip_fire")

func _remember(nodes: Array[Node3D], key: String) -> void:
    var positions: Array[Vector3] = []
    var rotations: Array[Vector3] = []
    for node in nodes:
        positions.append(node.position)
        rotations.append(node.rotation)
    rest[key + "_positions"] = positions
    rest[key + "_rotations"] = rotations

func set_pose(next_pose: String) -> void:
    if next_pose not in ["move", "aim", "hip_fire", "crouch_fire", "reload"]:
        return
    pose = next_pose
    _build_targets()

func set_weapon_profile(profile: String) -> void:
    weapon_profile = profile
    _build_targets()

func _build_targets() -> void:
    targets.clear()
    var arm_rot := Vector3(-0.72, 0.0, 0.32)
    var forearm_rot := Vector3(-0.82, 0.0, 0.24)
    var hand_offset := Vector3.ZERO
    var rifle_offset := Vector3.ZERO
    var rifle_rot := Vector3.ZERO
    var torso_offset := Vector3.ZERO
    var torso_rot := Vector3.ZERO
    var leg_rot := Vector3.ZERO

    match pose:
        "aim":
            arm_rot = Vector3(-0.88, 0.0, 0.24)
            forearm_rot = Vector3(-1.02, 0.0, 0.18)
            rifle_offset = Vector3(0.0, 0.055, -0.075)
            rifle_rot = Vector3(-0.035, 0.0, 0.0)
            torso_rot.x = -0.035
        "hip_fire":
            arm_rot = Vector3(-0.72, 0.0, 0.32)
            forearm_rot = Vector3(-0.82, 0.0, 0.24)
        "crouch_fire":
            arm_rot = Vector3(-0.82, 0.0, 0.28)
            forearm_rot = Vector3(-0.98, 0.0, 0.20)
            rifle_offset = Vector3(0.0, -0.055, -0.025)
            torso_offset = Vector3(0.0, -0.16, 0.0)
            torso_rot.x = -0.10
            leg_rot = Vector3(-0.48, 0.0, 0.0)
        "reload":
            arm_rot = Vector3(-0.45, 0.0, 0.38)
            forearm_rot = Vector3(-0.28, 0.0, 0.18)
            rifle_offset = Vector3(0.0, -0.12, 0.10)
            rifle_rot = Vector3(0.28, 0.0, 0.0)
        "move":
            arm_rot = Vector3(-0.55, 0.0, 0.38)
            forearm_rot = Vector3(-0.62, 0.0, 0.28)

    # Weapon families need different support-hand reach and balance.
    match weapon_profile:
        "lmg":
            rifle_offset.x -= 0.035
            arm_rot.x -= 0.08
            forearm_rot.x -= 0.10
        "launcher":
            rifle_offset.y += 0.035
            arm_rot.x += 0.08
        "pistol":
            rifle_offset.x += 0.06
            forearm_rot.x += 0.12
        "smg":
            rifle_offset.z += 0.025

    var arm_positions: Array = rest.get("arms_positions", [])
    var arm_rotations: Array = rest.get("arms_rotations", [])
    var fore_positions: Array = rest.get("forearms_positions", [])
    var fore_rotations: Array = rest.get("forearms_rotations", [])
    var hand_positions: Array = rest.get("hands_positions", [])
    var hand_rotations: Array = rest.get("hands_rotations", [])
    var leg_positions: Array = rest.get("legs_positions", [])
    var leg_rotations: Array = rest.get("legs_rotations", [])

    targets["arms"] = []
    for i in range(upper_arms.size()):
        var side := -1.0 if i == 0 else 1.0
        targets["arms"].append({"position": arm_positions[i], "rotation": Vector3(arm_rot.x, arm_rot.y, side * arm_rot.z)})
    targets["forearms"] = []
    for i in range(forearms.size()):
        var side := -1.0 if i == 0 else 1.0
        targets["forearms"].append({"position": fore_positions[i] + Vector3(side * 0.015, 0.0, 0.0), "rotation": Vector3(forearm_rot.x, forearm_rot.y, side * forearm_rot.z)})
    targets["hands"] = []
    for i in range(hands.size()):
        var side := -1.0 if i == 0 else 1.0
        targets["hands"].append({"position": hand_positions[i] + hand_offset + Vector3(side * 0.01, 0.0, 0.0), "rotation": hand_rotations[i]})
    targets["legs"] = []
    for i in range(legs.size()):
        targets["legs"].append({"position": leg_positions[i], "rotation": Vector3(leg_rot.x if i == 0 else -leg_rot.x, 0.0, leg_rot.z)})
    if is_instance_valid(rifle):
        targets["rifle_position"] = rest["rifle_position"] + rifle_offset
        targets["rifle_rotation"] = rest["rifle_rotation"] + rifle_rot
    if is_instance_valid(torso):
        targets["torso_position"] = rest["torso_position"] + torso_offset
        targets["torso_rotation"] = rest["torso_rotation"] + torso_rot
    if is_instance_valid(head):
        targets["head_position"] = rest["head_position"] + torso_offset
        targets["head_rotation"] = rest["head_rotation"] + Vector3(-torso_rot.x * 0.5, 0.0, 0.0)

func _process(delta: float) -> void:
    _blend_nodes(upper_arms, "arms", delta)
    _blend_nodes(forearms, "forearms", delta)
    _blend_nodes(hands, "hands", delta)
    if pose == "crouch_fire":
        _blend_nodes(legs, "legs", delta)
    var weight := minf(delta * blend_speed, 1.0)
    if is_instance_valid(rifle) and targets.has("rifle_position"):
        rifle.position = rifle.position.lerp(targets["rifle_position"], weight)
        rifle.rotation = rifle.rotation.lerp(targets["rifle_rotation"], weight)
    if is_instance_valid(torso) and targets.has("torso_position"):
        torso.position = torso.position.lerp(targets["torso_position"], weight)
        torso.rotation = torso.rotation.lerp(targets["torso_rotation"], weight)
    if is_instance_valid(head) and targets.has("head_position"):
        head.position = head.position.lerp(targets["head_position"], weight)
        head.rotation = head.rotation.lerp(targets["head_rotation"], weight)

func _blend_nodes(nodes: Array[Node3D], key: String, delta: float) -> void:
    if not targets.has(key):
        return
    var poses: Array = targets[key]
    var weight := minf(delta * blend_speed, 1.0)
    for i in range(mini(nodes.size(), poses.size())):
        if not is_instance_valid(nodes[i]):
            continue
        nodes[i].position = nodes[i].position.lerp(poses[i]["position"], weight)
        nodes[i].rotation = nodes[i].rotation.lerp(poses[i]["rotation"], weight)
