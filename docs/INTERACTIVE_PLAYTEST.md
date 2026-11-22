# HUNGER FOR WAR — Interactive Editor Playtest

This is the first **visual and gameplay-feel** pass after automated validation. It is a test guide, not a claim that these checks have already passed.

## 1. Open the validated project

1. In Godot **4.7.2**, import/open the repository project.
2. Select the project folder containing `project.godot`.
3. Let the editor finish importing the GLB and other assets. Wait for the filesystem scan/import progress to finish.
4. Confirm the main scene is `res://scenes/main.tscn` (Project → Project Settings → Application → Run → Main Scene).
5. Save nothing and change no gameplay settings during the baseline pass.
6. Press **F6 only if you deliberately want the currently open scene**. For the full game, press **F5 (Run Project)**.

If the editor reports an import or script error, stop and capture the complete first error from the Output/Debugger panel before changing anything.

## 2. Desktop keyboard and mouse controls

| Action | Control |
|---|---|
| Move | W / A / S / D |
| Look | Mouse |
| Fire | Left mouse button |
| Aim down sights | Hold right mouse button |
| Reload | R |
| Previous / next weapon | Q / E |
| Sprint | Hold Shift |
| Crouch | Hold Ctrl |
| Prone | Hold Z |
| Jump | Space |
| Release mouse capture | Esc |

The game starts by capturing the mouse. Avoid pressing Esc during the baseline combat pass unless you need to release the pointer.

## 3. First launch and deployment

- [ ] The battlefield appears without a black screen, missing meshes, or editor/runtime errors.
- [ ] The pre-deployment loadout panel appears and the battlefield remains paused until deployment.
- [ ] The M4 is visible and held in a stable first-person position.
- [ ] Press **DEPLOY TO BATTLE** and confirm the game becomes active.
- [ ] HUD health, ammunition, weapon name, and mission objective are readable and not clipped.

## 4. Player movement, stance, and camera

Test each stance on level ground, then near a wall or low ceiling if available.

- [ ] Standing: normal eye height; horizon remains level; no sudden drop to floor level.
- [ ] Crouch: camera lowers smoothly to a believable crouched eye height; weapon remains visible and aligned.
- [ ] Prone: camera lowers to a believable prone viewpoint without sinking below the ground or clipping through terrain.
- [ ] Return from prone → crouch → stand: each transition is smooth and collision-safe.
- [ ] Move forward/backward and strafe in each stance; no unexpected sliding, jitter, or getting stuck.
- [ ] Sprint and jump behave as expected; sprint does not remain stuck on after release.
- [ ] Turn the camera quickly and slowly; no unexpected snapping, inversion, or floor-facing camera behavior.

## 5. First-person weapon presentation and firing

- [ ] Rifle stays attached to the first-person camera/weapon mount and does not float away from the view.
- [ ] Weapon is not centered across the screen in an obstructive way.
- [ ] Aim-down-sights brings the sights toward the center of the view and returns cleanly when released.
- [ ] Fire, recoil, muzzle flash, hit marker, reload, and ammunition count respond correctly.
- [ ] Switch weapons with Q/E; each weapon remains visible and does not leave a detached model behind.
- [ ] Test prone and crouched aiming separately; note any clipping or broken weapon placement.

## 6. Soldier model, animation, and battlefield AI

The current main-scene startup log previously reported **9 enemy soldiers and 6 friendly woodland soldiers**. Confirm what actually appears in the editor viewport.

- [ ] Friendly and hostile soldiers are visible, correctly scaled, and standing on the terrain.
- [ ] No floating rifles, detached limbs, stretched arms, or arms-out running pose.
- [ ] Rifle grip looks plausible while soldiers move, aim, and fire.
- [ ] Soldiers walk/run with visible leg motion rather than sliding.
- [ ] Friendly soldiers are distinguishable from enemies.
- [ ] Enemies detect/engage the player, fire, and move rather than all remaining idle.
- [ ] Observe whether enemies use cover and whether their approach/flanking movement gets blocked by buildings or props.
- [ ] No soldiers spawn inside the ground, inside walls, or in unreachable positions.

## 7. Objectives and stability

- [ ] Alpha objective marker and capture HUD are visible.
- [ ] Enter Alpha's capture area and verify progress advances when no enemy contests it.
- [ ] If an enemy is in the zone, verify capture is contested.
- [ ] After Alpha, verify Bravo becomes the active objective.
- [ ] Watch the Output and Debugger panels throughout play: no red script errors, invalid-call errors, or repeated warnings.
- [ ] Play continuously for at least 5 minutes and note major frame drops, freezes, or crashes.

## 8. Record findings before making fixes

For every issue, record:
- **Where:** editor version, scene/area, and player stance.
- **What happened:** exact visible behavior.
- **How to reproduce:** numbered steps.
- **Expected vs actual:** what should happen and what happened.
- **Evidence:** screenshot or short video, plus the first related Output/Debugger error if present.

### Playtest result

- Godot version:
- Device / operating system:
- Renderer (if known):
- First launch: PASS / FAIL
- Movement and stances: PASS / FAIL
- First-person weapon: PASS / FAIL
- Soldier model and animation: PASS / FAIL
- Enemy/friendly AI: PASS / FAIL
- Objectives: PASS / FAIL
- Five-minute stability: PASS / FAIL
- Highest-priority issue:

**Important:** The GitHub Actions run validates asset import, parsing, 18 stance/camera smoke checks, weapon attachment to `Bip01_R_Hand`, 180 automated movement/aim physics frames, and a headless main-scene launch. It does not render the game in a graphical editor or verify visual quality, input feel, AI behavior quality, or real-device performance. Those are the purpose of this playtest.
