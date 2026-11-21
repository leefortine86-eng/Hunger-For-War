# HUNGER FOR WAR — Free 3D Asset Pipeline

## Non-negotiable budget rule

**The project must not require the user to spend money.** Do not add paid asset packs, subscriptions, paid plugins, or paid tools as dependencies. Prefer CC0/public-domain assets and genuinely free tools. A free download that requires payment for commercial rights is not acceptable.

Before importing any third-party asset, record its exact source page, creator, license, and any attribution requirement in `ASSET_CREDITS.md`. Do not assume an asset is free because a preview or download button says "free". Check the license for the individual asset.

## Asset goals

Replace the current primitive-only soldier and weapon presentation with:
- Rigged, human-proportioned infantry models with separate helmet, plate carrier, pouches, backpack, gloves, boots, and weapon attachment points.
- Distinct friendly and hostile uniform materials and camouflage palettes.
- Weapon-specific models with separate receiver, barrel, handguard, stock, magazine, optic, muzzle device, and grip components where practical.
- Authored animation clips for idle, walk, run, crouch, aim, fire, reload, weapon raise/lower, hit reaction, and death.
- PBR material maps where available: base color/albedo, normal, roughness, metallic, and ambient occlusion.

## Free sources to evaluate

These are candidate sources, not assets already imported into the game:
- Poly Haven — https://polyhaven.com/license — its asset library is CC0, including models, textures, and HDRIs. No attribution is required, though credit is appreciated.
- ambientCG — https://ambientcg.com/license — use only assets whose individual page confirms the CC0 license.
- Mixamo — https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html — Adobe says Mixamo is free and its characters/animations may be used in personal, commercial, and non-profit video games. It requires an Adobe ID; do not purchase a subscription for this project.
- Godot import guidance — https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html — use glTF 2.0 / GLB as the preferred interchange format.

Free libraries may not contain a suitable realistic modern soldier or weapon. Do not force a stylized or mismatched asset into the game just because it is free. If no suitable licensed model is available, leave that slot clearly marked as pending and plan an original asset made with free tools.

## Reviewed candidates

See [`ASSET_CANDIDATES.md`](ASSET_CANDIDATES.md) for the first license and quality review. The rigged Male Soldier 03 is only a provisional test candidate; the reviewed rifle and Arctic Station pack are not approved as final game assets. No candidate has been integrated into gameplay.

## Repository layout

Place accepted files in these locations:
- `assets/characters/friendly/`
- `assets/characters/hostile/`
- `assets/weapons/`
- `assets/animations/`
- `assets/materials/`
- `assets/textures/`
- `assets/reference/` (licensed references only; do not commit copyrighted game extracts)

Use `.glb` for self-contained models and rigs where practical. Keep source textures and license/credit records alongside the assets when they are separate. Avoid committing temporary exports, duplicate archives, or generated Godot import-cache files.

## Godot integration rules

1. Import a candidate into a separate test scene before replacing the current working soldier or weapon.
2. Confirm scale, forward direction, origin/pivot, skeleton hierarchy, material appearance, and animation names.
3. Verify animation clips in Godot's import preview and AnimationPlayer before wiring them into gameplay.
4. Keep the current playable prototype intact until the replacement is visibly working.
5. Prefer shared skeletons/materials and animation reuse across faction variants to reduce memory and draw-call cost.
6. Use sensible texture sizes and mesh detail tiers. Mobile performance matters; console-quality assets must be scalable, not simply maximum-resolution everywhere.
7. Keep weapon view models separate from world/third-person weapon meshes when their camera scale and detail requirements differ.

## First asset milestone

1. Find and license-check a realistic rigged soldier base model.
2. Establish a clean Godot character scene with an AnimationPlayer and a reusable animation library.
3. Bring in and verify the core movement and combat clips.
4. Create friendly and hostile material variants without changing the direct first-person FPS design.
5. Replace the first-person weapon prototype with one detailed, properly textured rifle and verify aim, firing, reload, and weapon switching.
6. Only after that pipeline works, expand to the rest of the arsenal and additional character variants.

## Current status

This file establishes the zero-cost sourcing and integration rules only. **No external soldier, weapon, or animation asset is claimed to have been downloaded or integrated yet.** Existing procedural models remain in use until replacements pass the test-scene checks above.
