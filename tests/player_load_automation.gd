extends Node

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const SOLDIER_SCENE: PackedScene = preload("res://assets/characters/Military_Male_03.glb")
const SOLDIER_ANIMATOR_SCRIPT: Script = preload("res://scripts/glb_soldier_animator.gd")

func _ready() -> void:
	call_deferred("_run_automation")

func _run_automation() -> void:
	print("PLAYER LOAD TEST: starting headless player/equipment/movement/aim automation")

	# A simple physical floor keeps the CharacterBody3D grounded during movement.
	var floor_body := StaticBody3D.new()
	floor_body.name = "AutomationFloor"
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(40.0, 1.0, 40.0)
	floor_collision.shape = floor_shape
	floor_body.add_child(floor_collision)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	get_tree().root.add_child(floor_body)

	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	if player == null:
		_fail("Player scene did not instantiate.")
		return
	player.name = "AutomationPlayer"
	player.position = Vector3(0.0, 0.05, 0.0)
	get_tree().root.add_child(player)
	await get_tree().process_frame
	await get_tree().physics_frame

	var controller := player.get_node_or_null("Controller") as TacticalPlayerController
	var camera := player.get_node_or_null("Camera3D") as PlayerCameraRig
	var weapon := player.get_node_or_null("Camera3D/Weapon") as Node3D
	if controller == null or not controller.is_ready_for_gameplay():
		_fail("Player controller did not initialize.")
		return
	if camera == null or weapon == null:
		_fail("Player camera or weapon node is missing.")
		return
	print("PLAYER LOAD TEST: player scene spawned; controller ready")

	# Load the real imported soldier rig and bind its animator to the player.
	var soldier := SOLDIER_SCENE.instantiate() as Node3D
	if soldier == null:
		_fail("Imported soldier GLB did not instantiate.")
		return
	soldier.name = "AutomationSoldierRig"
	player.add_child(soldier)
	var animator := Node3D.new()
	animator.name = "GLBSoldierAnimator"
	animator.set_script(SOLDIER_ANIMATOR_SCRIPT)
	soldier.add_child(animator)
	await get_tree().process_frame
	await get_tree().process_frame

	if not is_instance_valid(animator.get("skeleton")):
		_fail("Animator did not bind a Skeleton3D from the imported soldier.")
		return
	if str(animator.get("right_hand_bone")).is_empty():
		_fail("Imported soldier rig has no recognized right-hand bone.")
		return

	# Equip the player's real weapon node to the imported rig's right-hand bone.
	animator.call("attach_weapon_to_hand", weapon)
	await get_tree().process_frame
	await get_tree().process_frame
	var attachment := animator.get("weapon_attachment") as BoneAttachment3D
	if attachment == null:
		_fail("Weapon attachment node was not created.")
		return
	if weapon.get_parent() != attachment:
		_fail("Weapon is not parented beneath the right-hand BoneAttachment3D.")
		return
	if attachment.bone_name != str(animator.get("right_hand_bone")):
		_fail("Weapon BoneAttachment3D is bound to the wrong bone.")
		return
	print("PLAYER LOAD TEST: weapon attached to bone ", attachment.bone_name)

	# Exercise continuous movement and repeated aim transitions under physics load.
	var initial_position: Vector3 = player.global_position
	for frame_index in range(180):
		var aiming_now: bool = (frame_index % 60) < 40
		weapon.call("set_aiming", aiming_now)
		camera.set_aiming(aiming_now)
		camera.feed_look_motion(Vector2(0.35, -0.18))
		controller.physics_step(
			1.0 / 60.0,
			Vector2(0.15, -1.0),
			frame_index % 90 < 30,
			false,
			false,
			false
		)
		await get_tree().physics_frame
		if frame_index % 30 == 0:
			await get_tree().process_frame

	if player.global_position.distance_to(initial_position) < 0.1:
		_fail("Movement simulation did not move the player.")
		return
	if not is_instance_valid(weapon) or weapon.get_parent() != attachment:
		_fail("Weapon detached or became invalid during movement/aim simulation.")
		return
	if not controller.is_ready_for_gameplay():
		_fail("Player controller became unready during simulation.")
		return

	print("PLAYER LOAD TEST: 180 physics frames of movement and aim transitions passed")
	print("PLAYER LOAD TEST: PASS")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("PLAYER LOAD TEST FAILED: " + message)
	get_tree().quit(1)
