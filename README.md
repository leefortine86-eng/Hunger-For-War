# HUNGER FOR WAR

An original modern military first-person shooter being developed in Godot, with Android as the first target and PC support planned.

## Development direction

The goal is a polished, tactical FPS with high-quality 3D presentation and mobile-friendly controls. The game will use original assets and systems while taking broad inspiration from modern military shooters.

## Feature roadmap

### Player and controls
- [x] Mobile look controls and virtual movement joystick
- [x] Health and ammunition HUD
- [x] Sprint controls for keyboard and touch
- [x] Crouch controls for keyboard and touch
- [x] Jump controls for keyboard and touch
- [ ] Reliable movement and collision testing on Android
- [x] Aim-down-sights controls and zoomed camera view
- [x] First-person weapon sway, movement bob, recoil, and reload animation

### Weapons and combat
- [x] Basic hitscan weapon and magazine / reserve ammunition
- [x] Reloading
- [x] First-person rifle prototype, recoil, muzzle flash, and firing feedback
- [x] Expandable 53-weapon catalog (all 38 WARDOGS entries plus 15 additional Arma Reforger base-game portable weapons) inspired by WARDOGS and Arma Reforger
- [x] Mobile arsenal dropdown and keyboard / touch weapon cycling
- [x] Distinct procedural weapon silhouettes by weapon class
- [x] Physical rocket and grenade projectiles with gravity, impact detection, blast radius, and distance-based damage falloff
- [x] Weapon attachment system with optics, suppressors, grips, flashlight / laser, and extended magazines
- [x] Refined procedural weapon barrels, muzzle devices, receiver controls, and handguard rails
- [ ] Improved hit effects and combat feedback

### Enemies and AI
- [x] Basic enemy soldier prototype
- [x] Basic procedural walk-cycle animation for friendly and enemy soldiers
- [x] First-pass distinct faction uniforms: woodland-green allies with blue ID markings and tan-grey hostiles with red ID markings
- [x] First-pass modern soldier equipment: helmet rails/NVG mounts, eye protection, headsets, plate-carrier pouches, radios, knee pads, gloves, boots, and class-neutral rifle accessories
- [x] Subdued woodland camouflage panels on friendly uniforms and distinct hostile tan/grey kit
- [x] Procedural shader-based woodland and dusty camouflage patterns on uniform surfaces
- [ ] Authored high-resolution character textures, higher-detail character meshes, and animation blending
- [x] Ranged enemy attacks with line-of-sight checks and distance keeping
- [x] Friendly three-person fireteam that follows the player and engages visible enemies
- [x] Enemies seek nearby defensive cover after taking damage
- [x] Basic coordinated enemy flanking: hostile soldiers choose alternating lateral approach positions when operating as a squad
- [ ] Advanced enemy awareness, obstacle-aware flanking, suppression, and squad tactics
- [ ] Enemy return fire and squad behavior

### Battlefield and presentation
- [x] Prototype ground, lighting, cover, and test enemies
- [x] First-pass settlement environment with four enterable buildings, window openings, flat rooftops, a service road, checkpoint barriers, a burned-out transport wreck, utility poles, berms, scrub, perimeter pine trees, rock clusters, drainage banks, road markings, and supply props
- [x] Sequential Alpha and Bravo capture objectives with contested-zone logic and mission completion
- [x] First-pass original building interiors with a command planning table, communications console, barracks bunks, lockers, checkpoint desk, and outpost storage
- [x] First-pass defensive observation towers, firing bays, checkpoint canopy, radio mast, building service equipment, compound floodlights, modular blast walls, jersey barriers, equipment shade, and field generator
- [x] Building roof-access ladder props and rooftop ventilation details (visual-only; climbing is not implemented)
- [x] Subtle distance fog and a lightweight burned-wreck ember / smoke presentation
- [x] Procedural shader-based ground variation and weathered plaster / concrete surfaces
- [x] First-pass perimeter security fence, warning lamps, and layered sandbag firing bays
- [ ] True sculpted terrain elevation, detailed terrain decals, and destructible set dressing
- [ ] Vehicles and larger battlefield spaces
- [ ] Improved lighting, atmosphere, sound, and visual effects

### Interface and release
- [x] Basic health and ammunition display
- [x] Mission objective HUD and capture progress
- [ ] Combat indicators and expanded HUD
- [ ] Android performance and touch-layout optimization
- [ ] PC controls and compatibility pass

## Current development milestone

Core controls, a selectable multi-class arsenal, procedural weapon silhouettes, aiming, recoil, movement sway, reload motion, muzzle flash, ranged enemy combat, and sequential capture objectives are now in the project. A three-person friendly fireteam now follows the player in formation and provides supporting fire against visible enemies. The current catalog contains all 38 WARDOGS roster entries and the remaining unique portable weapons from the Arma Reforger base-game roster. Weapon stats are original prototype tuning values, not copied game balance. Rocket launchers and grenade launchers now fire physical projectiles with different speeds and trajectories, impact/fuse detonation, area damage, and a short explosion visual. Weapon attachments now have a mobile attachment panel, per-weapon saved loadouts, visible procedural attachment models, extended-magazine capacity, optic range bonuses, and grip recoil reductions. Suppressors reduce muzzle flash. Next development should add more class-specific firing behavior and a larger designed battlefield. Features are marked complete only when implemented; Android testing remains outstanding.


The settlement battlefield now has defensive observation towers, extra firing bays, a checkpoint canopy, roof ladder and ventilation props, subtle distance fog, and a lightweight wreck ember/smoke effect. The ladders are currently visual-only and are not climbable. The settlement battlefield also has additional terrain dressing: perimeter pine trees that frame concealed flanking routes, rock clusters, raised drainage banks, faded road markings, and supply props near the compounds. The next map is planned as a separate woodland military installation with its own layout, buildings, defensive positions, and capture objectives; it will be added after the settlement map is completed.


Faction visuals now distinguish friendly and hostile soldiers at a glance: friendly fireteam members wear woodland-green kit with blue identification panels and arm bands; hostile soldiers wear dusty tan/grey kit with red identification markings. The settlement compounds also gained external air-conditioning units, power cabinets, cable ducts, a command radio mast, and low-intensity floodlights. These are procedural prototype details and have not yet been performance-tested on Android.


Enemy combat now has a first tactical movement pass: when multiple hostiles are active, they alternate lateral approach positions instead of all advancing along the same direct line. This is lightweight steering rather than full navigation; obstacle-aware pathfinding, suppression behavior, and more advanced squad coordination remain future work. This change has not yet been tested in Godot or on Android.\n\nThe latest realism pass adds first-pass modern infantry kit to both factions: helmet accessory rails and NVG mounts, eye protection, headsets, plate-carrier magazine/utility pouches, radio antennas, knee protection, gloves, boots, and more complete rifle silhouettes. Friendly uniforms include muted woodland camouflage panels; hostile uniforms retain a separate dusty tan/grey palette and red faction identifiers. The settlement now also includes modular blast-wall and jersey-barrier positions, a camouflaged equipment staging shade, a field generator, and a tactical communications mast. These remain procedural low-poly prototypes; detailed scanned assets, texture maps, animation blending, and Android performance validation are still future work.

The visual-development pass now moves beyond single flat material colors: friendly and hostile uniform surfaces use procedural shader camouflage palettes; the battlefield ground has layered soil/vegetation variation; and building plaster/concrete surfaces have weathering variation. Weapon silhouettes gained cylindrical barrels, muzzle devices, side rails, charging handles, and receiver details. Building fronts gained additional window trim, door hardware, conduit, and junction boxes. The outpost perimeter now has a post-and-rail security fence, low warning lights, and individually layered sandbag courses around firing bays. These are lightweight procedural materials and geometry—not finished scanned textures or production character assets—and have not been validated in Godot or profiled on Android.


## Soldier proportion and equipment pass
- Refined friendly and hostile torso and head proportions to reduce the oversized capsule/sphere appearance.
- Added neck, pelvis and combat-belt transitions to make the body read more like a layered infantry uniform.
- Separated thigh and lower-leg shapes, added boot soles and more defined gloved hands.
- Preserved the existing faction camouflage, identifying colors, movement logic, combat behavior and mobile controls.
- These are still procedural low-poly character assemblies, not rigged or professionally sculpted character assets. The changes have not yet been validated in Godot or profiled on Android.


## Shoulder-ready rifle pose
- Repositioned friendly and hostile upper arms and forearms into a forward, bent support posture.
- Added visible grip-hand shapes near the rifle fore-end and grip area.
- Kept upper arms steady while the legs continue their walk cycle, avoiding the old arm-swing animation pulling the hands away from the weapon.
- The current weapon hold is a fixed procedural pose; hand-to-trigger alignment, reload/aim transitions and a true skeletal rig remain future work. Not yet tested in Godot.


## Blended soldier combat pose rig
- Added a reusable articulated procedural pose controller for upper arms, forearms, hands, rifle placement, torso and head.
- Friendly and hostile combat logic now blends between movement-ready, aimed fire, close hip-fire, crouched firing and reload poses.
- Added short simulated magazine cycles so soldiers visibly lower and manipulate their rifles during reload transitions before resuming fire.
- Pose profiles include different reach/balance offsets for rifle, SMG, LMG, pistol and launcher families; current AI soldiers use the rifle profile.
- This is an articulated procedural bridge using the existing mesh parts, not yet a weighted Skeleton3D rig with authored finger animation clips. Hand contact and trigger-finger alignment remain approximate, and the result has not been opened or tested in Godot. A true skeletal rig, weapon-specific hand meshes and authored animation clips remain a later quality step.


## Skeleton3D soldier rig milestone
- Added a procedural Skeleton3D hierarchy for pelvis, spine, neck, head, upper arms, forearms, hands and thighs.
- Existing procedural body, head, limb and rifle meshes are attached to skeleton bones through BoneAttachment3D nodes; the skeleton blends aiming, hip-fire, crouched-fire, movement and reload poses.
- Locomotion phase is passed into the skeleton controller for leg swing, while pose changes are blended rather than snapped.
- This is an intermediate articulated rig using attached primitive meshes, not yet a weighted skinned character mesh or a full AnimationTree/AnimationPlayer clip library. The new rig has not been executed in Godot in this environment, so editor/runtime compatibility and attachment alignment still need validation.
