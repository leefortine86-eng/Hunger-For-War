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
- [ ] Improved hit effects and combat feedback

### Enemies and AI
- [x] Basic enemy soldier prototype
- [x] Basic procedural walk-cycle animation for friendly and enemy soldiers
- [ ] Improved soldier models, materials, and animation blending
- [x] Ranged enemy attacks with line-of-sight checks and distance keeping
- [x] Friendly three-person fireteam that follows the player and engages visible enemies
- [x] Enemies seek nearby defensive cover after taking damage
- [ ] Broader enemy awareness, flanking, and squad tactics
- [ ] Enemy return fire and squad behavior

### Battlefield and presentation
- [x] Prototype ground, lighting, cover, and test enemies
- [x] First-pass settlement environment with four enterable buildings, window openings, flat rooftops, a service road, checkpoint barriers, a burned-out transport wreck, utility poles, berms, and scrub
- [x] Sequential Alpha and Bravo capture objectives with contested-zone logic and mission completion
- [ ] Higher-detail original building interiors, material variety, terrain elevation, and destructible-looking set dressing
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
