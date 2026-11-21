# HUNGER FOR WAR — 3D Asset Candidate Review

This is a sourcing review, not an import record. None of these files has been added to the game. The current playable prototype remains unchanged.

## Preferred route: Ara 3D Gen — build a custom soldier

- Online builder: https://ara3dgen.com/
- Source repository and technical details: https://github.com/TuriaArt/3d-gen-TU
- Cost/access: the project describes itself as free and open source, with no account, install, credits or export fees required for the online builder. Do not enter any paid AI/API key; those integrations are optional and unnecessary for the base character export.
- Licensing: generator code is MIT; its MakeHuman character data is CC0; the project states exported characters may be used commercially without attribution. Motion clips are credited to the CMU Graphics Lab motion-capture library.
- Relevant features: customizable camouflage fabric, tactical vest and combat helmet options; Mixamo-named game skeleton; a right-hand weapon socket; GLB export; shooter animations including rifle idle, aim, single/full-auto fire, reload, aiming walk/strafe, sprint, crouch aim/walk, hit reaction and death.
- Technical note: the project documents a 65-bone game rig option and Godot GLB import. The self-hosted route requires Node 20+, Git and a one-time download of approximately 420 MB of CC0 source data; that is not the preferred route for the user's Android-first workflow.
- Decision: **first-choice character creation route to evaluate**. Use the browser builder to create a woodland/modern combat operator, export a rigged GLB with only the required shooter clips, and test that exact file in a separate Godot scene. The tool's own claims are not a substitute for our Godot/Android validation.

## Candidate: Male Soldier 03 — provisional character test

- Source: https://models.codelove.in/models/military-male-03/
- Download: https://models.codelove.in/models/military-male-03.glb
- Format and size: GLB, 1.7 MB
- Published specification: 15,517 triangles, 80-bone biped skeleton, five materials, ten 1024 px textures, 1.85 m tall.
- License: MIT; the model page says commercial use is allowed. Keep the included license text with the model in any distribution.
- Animation availability: the model page previews ten compatible clips, including idle, walk and run. These are general-purpose clips, not a verified military combat animation set.
- Assessment: the visible preview has a helmet, camouflage uniform, body armour and basic tactical gear. It is a useful low-cost technical candidate for testing a rigged infantry character, but its visual fidelity and equipment detail have not been verified in Godot against the game's target WARDOGS / Arma Reforger-inspired quality.
- Decision: **provisional test candidate only**. Do not replace the current soldier until the GLB is imported and checked for rig quality, texture quality, silhouette, animation compatibility, scale and Android performance.

## Candidate: Assault Rifle — Arctic Station FPS Kit

- Source: https://3dassets.dev/assets/arctic-station-fps-kit-assault-rifle-23a5401c
- Direct model: https://cdn.3dassets.dev/assets/28502/v1/model.glb
- Format: GLB, approximately 877 KB.
- Published specification: 49,828 triangles, three materials, six rigid-part clips for magazine, bolt and stock.
- License: CC0 1.0 Universal; commercial use and modification allowed without attribution, according to the asset page.
- Important limitations: this is an original invented firearm archetype, not a model of a real weapon. It has no skeleton or skinning; only named rigid parts animate. The page reports that AI tools were used to create it.
- Decision: **do not use as the game's signature rifle yet**. Its polygon count is high for a single view-model weapon, and its invented design may not meet the desired realistic modern military equipment standard. Keep it as a possible reference/test asset only.

## Candidate: Arctic Station FPS Kit — not a character replacement

- Source: https://3dassets.dev/packs/arctic-station-fps-kit
- License: CC0 1.0 Universal.
- Published contents: 81 GLB models, 45.2 MB total, including twelve invented weapon archetypes and twelve posed operators.
- Important limitations: the operators are static posed figures; the pack has no rig, skeleton or skinning. The palette and setting are arctic, not the current game's woodland / modern combat environment. The pack is reported as AI-generated.
- Decision: **do not use as the main soldier or map replacement**. Individual props may be reconsidered only if they fit the setting and pass quality review.

## Acceptance gate

A candidate is not accepted merely because its page says free or game-ready. Before integration, the actual file must be obtained, its license retained, and the model opened in Godot. Check:
1. Real-world scale, forward axis, pivot and mesh orientation.
2. Skeleton hierarchy and deformation under walk, run, crouch and aim poses.
3. Whether required animation clips actually exist and look suitable in-game.
4. Materials and textures under the game's lighting.
5. Draw calls, triangle count, texture memory and performance on Android.
6. Whether it visually fits the modern realistic art direction.

If a candidate fails, leave it out. Do not spend money to fill the gap; continue searching or build an original asset using free tools.
