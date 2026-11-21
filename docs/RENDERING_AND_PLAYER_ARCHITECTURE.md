# HUNGER FOR WAR — Player and Rendering Architecture

## Player separation
- `scripts/player.gd` remains the gameplay coordinator for input, HUD, health, and weapon interaction.
- `scripts/player_movement.gd` owns CharacterBody3D velocity, gravity, jump, and capsule stance collision.
- `scripts/player_camera_rig.gd` owns stance camera height and aim FOV.
- Existing weapon, AI, and soldier animation scripts remain independent.

## Rendering targets
The project is configured for Forward+ as the desktop default and Mobile as the mobile renderer override. Confirm the actual renderer selected in each export preset and test on target devices before release. Keep Compatibility as a fallback profile for devices that cannot run the Mobile renderer reliably.

Recommended desktop Forward+ profile: directional shadows with PSSM, contact shadows where supported, SSAO, SSIL, SSR, glow, tonemapping/color adjustment, and volumetric fog. Enable effects selectively and profile GPU cost.

Recommended Android profile: Mobile renderer, reduced shadow atlas and shadow resolution, selective glow, no expensive screen-space effects by default, and scalable 3D render scale. Keep compatibility as fallback for devices that cannot run Mobile renderer reliably.

## 4K policy
4K output resolution and 4K texture assets are separate targets. Preserve source texture files at original resolution; use mipmaps, anisotropic filtering, and platform-appropriate import settings. Do not assume 4K output is practical on every Android device.

## Tactical PBR shader
`shaders/tactical_pbr.gdshader` provides albedo, normal, roughness, metallic, and AO texture inputs. Assign it through ShaderMaterial and populate all maps before use. It is a reusable starting material, not yet assigned to the SWAT model.

## Validation still required
Run the Godot 4.7.2 project on desktop and Android. Verify parser/import errors, capsule clearance during stance transitions, camera eye height, touch input, weapon behavior, shadow quality, shader maps, and frame time. Do not claim visual validation from CI alone.


## Tactical controller additions
- Acceleration and deceleration are independently tunable; movement eases into and out of velocity instead of snapping.
- Separate tactical walk, sprint, crouch, and prone speeds.
- Stamina drains during sprint and active movement, recovers after a delay, and fatigue increases weapon aim sway.
- Camera rig applies procedural weapon positional lag from look input and movement bob from horizontal speed.
- Tune values on target hardware and test whether the chosen speeds fit existing level scale and AI pacing.
- Current stamina values are gameplay tuning defaults, not measured realism values. Add HUD stamina visualization and playtest balancing before release.
