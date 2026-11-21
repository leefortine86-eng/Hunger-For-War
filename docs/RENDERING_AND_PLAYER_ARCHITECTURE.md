# HUNGER FOR WAR — Player and Rendering Architecture

## Player separation
- `scripts/player.gd` remains the gameplay coordinator for input, HUD, health, and weapon interaction.
- `scripts/player_movement.gd` owns CharacterBody3D velocity, gravity, jump, and capsule stance collision.
- `scripts/player_camera_rig.gd` owns stance camera height and aim FOV.
- Existing weapon, AI, and soldier animation scripts remain independent.

## Rendering targets
The current project remains on Compatibility for this first safe refactor. Do not switch the whole project to Forward+ until a desktop-only profile and an Android Mobile profile have been tested on target devices. Godot project rendering method selection is a project-level setting; the mobile override is not a universal guarantee that every export will select the desired renderer.

Recommended desktop Forward+ profile: directional shadows with PSSM, contact shadows where supported, SSAO, SSIL, SSR, glow, tonemapping/color adjustment, and volumetric fog. Enable effects selectively and profile GPU cost.

Recommended Android profile: Mobile renderer, reduced shadow atlas and shadow resolution, selective glow, no expensive screen-space effects by default, and scalable 3D render scale. Keep compatibility as fallback for devices that cannot run Mobile renderer reliably.

## 4K policy
4K output resolution and 4K texture assets are separate targets. Preserve source texture files at original resolution; use mipmaps, anisotropic filtering, and platform-appropriate import settings. Do not assume 4K output is practical on every Android device.

## Tactical PBR shader
`shaders/tactical_pbr.gdshader` provides albedo, normal, roughness, metallic, and AO texture inputs. Assign it through ShaderMaterial and populate all maps before use. It is a reusable starting material, not yet assigned to the SWAT model.

## Validation still required
Run the Godot 4.7.2 project on desktop and Android. Verify parser/import errors, capsule clearance during stance transitions, camera eye height, touch input, weapon behavior, shadow quality, shader maps, and frame time. Do not claim visual validation from CI alone.
