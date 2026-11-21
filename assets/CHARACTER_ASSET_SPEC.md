# HUNGER FOR WAR — First Infantry Character Build Specification

Use this specification in the free Ara 3D Gen browser builder: https://ara3dgen.com/

## Art direction
Create an original modern infantry operator that fits HUNGER FOR WAR's grounded woodland combat setting. The intended quality target is realistic modern military presentation inspired by WARDOGS and Arma Reforger, not a stylized, cartoon, sci-fi or low-poly look.

### Character appearance
- Adult human proportions; athletic but believable, not exaggerated.
- Modern woodland camouflage combat uniform with long sleeves and trousers.
- Practical plate carrier with MOLLE-style pouches, belt, gloves and knee protection where available.
- Modern combat helmet with a simple mount/rails; clear eye protection optional.
- Realistic combat boots.
- Restrained olive, woodland green, brown and muted tan palette.
- No oversized armour, glowing details, fantasy accessories, giant insignia or real-world copyrighted game branding.
- Keep friendly and hostile versions visually distinct through different camouflage/material palettes and small original identifiers, not through neon colors.

## Export settings
- Export format: GLB.
- Include mesh, PBR materials/textures, skinning, skeleton and selected animation clips.
- Skeleton: game rig / Mixamo-compatible 65-bone option.
- Pose: A-pose if supported; retain the right-hand weapon socket.
- Detail: begin with the medium game-ready tier for the first Godot/Android test. Do not use the high/HD tier until memory and frame-time are measured.
- Include only the required clips below to keep the file manageable.

## Required animation clips
1. Idle / rifle low-ready.
2. Rifle aim idle.
3. Walk and aiming walk.
4. Run and sprint.
5. Backward walk and left/right strafe.
6. Crouch idle, crouch aim and crouch walk.
7. Single-shot fire and full-auto fire.
8. Rifle reload.
9. Hit reaction.
10. Death / fall.
11. Optional grenade throw if the builder exports it cleanly.

## Integration gate
The export is a candidate until it passes all checks in a separate Godot test scene:
- GLB imports without errors and preserves textures.
- Scale, facing direction, rest pose and weapon socket are correct.
- Walk/run/crouch/aim/fire/reload clips play without broken limbs or foot sliding severe enough to reject.
- Both hands stay correctly positioned on the rifle during aim/fire/reload.
- Character materials read clearly in the existing woodland map lighting.
- Android performance is acceptable before replacing the existing procedural soldier.
- Friendly and hostile variants share a compatible skeleton so animations can be reused.

Do not replace the existing playable soldier until the imported model passes this gate. No paid subscription, export credit, or AI/API key is required or permitted for this workflow.
