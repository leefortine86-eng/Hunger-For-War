# HUNGER FOR WAR — Permanent Development and Architecture Standard

## Design benchmark

HUNGER FOR WAR targets grounded tactical combat, survival, extraction, squad dynamics, and large-world battlefield immersion. War Dogs and Arma Reforger are gameplay and quality references, not source-code or asset templates. Implement original systems and content.

## Non-negotiable engineering rules

1. Preserve established gameplay and project assets unless a reviewed change explicitly replaces them.
2. Use composition: one component, one responsibility.
3. Keep input/presentation, player orchestration, movement physics, camera behavior, health, stamina, weapons, ballistics, inventory, AI, missions, and persistence independently owned.
4. Communicate across systems through documented methods, typed references, signals, and Resources; avoid hidden cross-system state.
5. Validate required node references at startup and fail clearly rather than silently continuing in a broken state.
6. Never add placeholder implementations and describe them as complete.
7. Add or update regression coverage whenever behavior or interfaces change.
8. Keep changes on a feature branch and review before merging into main.
9. Do not claim runtime, visual, Android, or desktop validation until that exact validation has been performed.
10. Keep Godot version compatibility explicit. The current project baseline is Godot 4.7.2.

## Player component boundaries

- `player.gd`: input collection, touch controls, HUD, and weapon UI integration.
- `player_controller.gd`: coordinates the body, movement component, and camera component for each physics frame.
- `player_movement.gd`: CharacterBody3D velocity, acceleration/deceleration, gravity, jump, stamina, fatigue, and stance collision.
- `player_camera_rig.gd`: camera stance height, aim FOV, look inertia, movement bob, and fatigue sway.
- `weapon.gd`: weapon state, firing, reload, aiming, attachments, and weapon-specific behavior.

A component must not take ownership of another component's responsibility. For example, the camera does not calculate movement physics, and the movement component does not draw HUD elements.

## Player controller contract

The player controller accepts already-collected local movement input and explicit sprint/crouch/prone/jump intent. It clamps input magnitude, delegates physical simulation to PlayerMovement, then sends resulting movement/fatigue state to PlayerCameraRig. It does not own input devices, HUD, weapon firing, or inventory.

Required startup dependencies:
- Parent is a CharacterBody3D.
- A PlayerMovement component exists at the configured movement path.
- A PlayerCameraRig exists at the configured camera path.

Missing dependencies are fatal to controller initialization and must produce a clear error.

## Definition of done

A system is not complete until:
- GDScript parses in the target Godot version.
- Referenced scenes, resources, and node paths resolve.
- Integration behavior is exercised in the actual project.
- Existing controls and mechanics pass regression checks.
- Relevant runtime and visual checks are completed on target platforms.
- Documentation reflects the actual implementation.

Automated CI is necessary but does not prove animation quality, weapon alignment, tactile feel, AI quality, or visual fidelity. These require in-engine playtesting and inspection.
