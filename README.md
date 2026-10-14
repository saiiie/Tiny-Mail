# Tiny Mail

## Week 7 - Juice, Save/Load & Optimization

Implementation is ready for manual review. Profiler capture and the second real peer playtest remain pending. No editor wiring or navigation baking is required.

### Polish

- Puddle and crow impacts trigger a fixed Camera2D shake: at most 2 pixels per axis for 0.14 seconds. Original whole-level framing and the steady HUD are preserved. Camera processing stops when the effect ends.
- Brief hit-stop uses Engine.time_scale = 0.01 for 0.06 real seconds. GameSession restores the previous scale using a real-time deadline, on scene changes, and on exit. The level also restores it when removed. After 0.08 real seconds the rabbit returns to Start, and the crow resets as before.
- Delivery Complete! fades in and out using a HUD Tween before the 0.85-second Level 1 transition. Progress Saved is included only when the checkpoint write succeeds. The final completion panel also fades in. Gameplay timing pauses during delivery feedback.

### Save / Load

scenes/ui/save_manager.gd is a small SaveManager autoload with save_game(), load_game(), has_save(), and clear_save(). GameSession handles new-game and Continue routing.

- Format: JSON, version 1.
- Location: user://tiny_post_save.json (never res://). In Godot, use Project > Open User Data Folder to find it. Default Windows location: %APPDATA%/Godot/app_userdata/Tiny Post/tiny_post_save.json.
- Data: version, level (the current checkpoint scene), elapsed_seconds (gameplay time at that checkpoint). Save validity is derived by validating the file; it is not a separately trusted Boolean.
- Autosave: entering either level, completing Level 1 (saves Level 2 before transition), and completing Level 2. Direct F6 level runs also save that level.
- Start / Play Again clears the old save, resets time, and starts Level 1, creating a fresh checkpoint upon entry.
- Continue is disabled without a valid save. It restores Level 1 or Level 2 at START with the saved elapsed time. After final completion it replays Level 2 with that saved time; completion itself is not persisted.
- This is checkpoint persistence: closing mid-level loses time accumulated since the latest checkpoint. Exact positions and temporary states are not saved.
- Missing, unreadable, malformed, wrong-version, unknown-level, missing-resource, or invalid-timer saves are rejected. Only the two known level paths are accepted. If the save becomes invalid after the menu opens, Continue safely starts a new game.

Example:

```json
{"version":1,"level":"res://scenes/levels/level_2.tscn","elapsed_seconds":65.0}
```

### Optimization

**Optimization implemented for profiling review.** In scenes/ui/hud.gd, timer text formatting and Label assignment happen only when the displayed whole second changes, with a cached Label reference. Previously both happened every rendered frame. This reduces unnecessary string creation, node lookup, and label assignment while preserving the display. The Godot Profiler will be used to verify runtime impact; no performance measurements are claimed.

The existing enemy already updates its chase navigation target every 0.15 seconds. That implementation remains unchanged.

### Manual Godot tests

1. Open project.godot in Godot 4.7.2, wait for imports, and press F5. With no save, Continue must be disabled. To test a clean state, stop the game and back up/remove only tiny_post_save.json from Project > Open User Data Folder.
2. Choose Start. Check Level 1, timer starting at 00:00, four-direction movement/animations, idle, dust, hedge collisions, music, and HUD. A Level 1 JSON checkpoint should now exist.
3. Touch a puddle. Check a small shake, very brief impact pause, splash audio, reset to START, and normal speed afterward. Try R and Escape during impacts; neither should leave the game slowed down.
4. Complete Level 1. Check delivery chime, tweened Delivery Complete! / Progress Saved, then Level 2. Inspect the JSON: level must be res://scenes/levels/level_2.tscn with nonnegative elapsed_seconds.
5. Stop the game entirely (F8), run again (F5), and choose Continue. Check Level 2 at START with the checkpoint timer restored. Repeat closing/Continue with a Level 1 checkpoint.
6. Check crow PATROL, CHASE, pathfinding around hedges/puddles, contact impact/reset, and return to patrol. Check R retains the timer and Escape opens the menu. Complete Level 2 and check frozen timer, faded-in completion panel, stopped player/enemy/dust, Play Again, and Main Menu.
7. From a Level 2 save choose Start; confirm fresh Level 1/time and a Level 1 save. Test keyboard focus/Enter on all three menu buttons, Quit, and window resizing.
8. Stop the game; back up the save. Replace its content with invalid JSON, then run: Continue must be disabled and Start must work. Repeat with the example JSON but level set to res://missing.tscn (and optionally a negative elapsed_seconds). Restore the backup afterward if wanted. Do not edit saves while the game is running.
9. Visually review shake comfort, HUD readability, tween timing, particle appearance, and audio balance. Headless checks cannot establish these qualities.

### Manual Profiler steps (pending)

1. Press F5 in Godot and Start or Continue. Keep the game running.
2. Return to the editor and open the bottom Debugger panel, then its Profiler tab (the script Profiler, not Visual Profiler).
3. Click Start in the Profiler if capture is not already running.
4. Return to the game and play for roughly 30-60 seconds. Include Level 2 patrol/chase, movement, puddles, and delivery.
5. Return to the Profiler and stop capture. Inspect Frame Time, process/physics timing, and expand Script Functions. Use milliseconds, inspect a representative frame and a spike, and compare function time and call counts. Self time excludes time spent in callees; Inclusive includes it.
6. Record the largest obvious measured cost, its function/category, timing, hardware/run conditions, and a screenshot. Do not assume the HUD is the largest cost. Check the HUD update cost; a before/after comparison needs equivalent runs with the earlier timer implementation and this one. If differences are too small to measure reliably, report that.

Reference: [Godot Profiler documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html).

Profiler observation / largest measured cost:
[TO BE FILLED AFTER PROFILING]

Runtime impact of optimization:
[TO BE FILLED AFTER PROFILING]

### Week 7 Peer Playtest

Pending: conduct a real second 5-minute peer playtest. Ask the peer to try Start, impacts, delivery, closing/reopening and Continue, and menu controls. Record actual feedback, implement one resulting improvement, and retest it before marking this requirement complete.

Observation:
[TO BE FILLED AFTER PLAYTEST]

Improvement made:
[TO BE FILLED AFTER PLAYTEST]

### Week 7 validation

Run headless checks with Godot on PATH:

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --script tools/validate_project.gd
godot --headless --path . --script tools/validate_week3.gd
godot --headless --path . --script tools/validate_week4.gd
godot --headless --path . --script tools/validate_week5.gd
godot --headless --path . --script tools/validate_week6.gd
godot --headless --path . --script tools/validate_week7.gd
```

These suites write checkpoints; back up the save before running and restore it afterward. Week 7 deliberately clears/overwrites it with invalid and valid test data. Earlier regression waits now accommodate impact and delivery feedback delays. Headless checks do not replace visual/gameplay review, profiling, or peer testing.

Validation performed for Week 7 with Godot 4.7.2: headless editor import passed without parser/resource errors; project validation loaded 33 resources with zero failures; Week 3, 4, 5, 6, and 7 integration suites passed with zero failures. A paired --write-checkpoint / --read-checkpoint run of tools/validate_week7.gd in separate Godot processes restored Level 2 and its timer with zero failures. Existing user save contents were preserved around these runs. git diff --check passed. These checks cover movement/animation selection, particle emission flags, hazards, enemy FSM/navigation, audio playback states, HUD/menu flow, checkpoint validation, impact recovery, and tween state. Visual appearance, audible quality, measured profiling impact, and peer feedback remain unverified.

## Description

Tiny Mail is a cute 2D delivery game developed using Godot.

The player takes the role of a small mail carrier who travels around a neighborhood and delivers letters to the correct houses.

## Genre

2D Casual / Delivery

## Planned Features

- Four-direction player movement
- Multiple houses and delivery locations
- Random letter assignments
- Delivery interactions
- Delivery timer
- Score or completed-delivery counter
- Incorrect delivery penalties
- Multiple neighborhoods or levels
- Character and environment animations
- Sound effects and music
- Start and results screens

## Development Status

### Week 1
- Initial Godot project setup
- Main Node2D scene
- Placeholder Player Sprite2D
- Running 2D scene

### Week 2
- CharacterBody2D player controller
- WASD and arrow-key movement
- Player collision shape
- Delivery-area collision detection
- Interactive delivery using the E key
- Squash-and-stretch delivery feedback

### Week 3
- Two saved, playable neighborhood levels with actual TileMapLayer tiles and a shared TileSet.
- Level 1: 128-pixel-wide paths and two puddles. Level 2: 96-pixel-wide winding paths and five puddles.
- Puddles reset the rabbit to START; hedges and fences block shortcuts.
- Walk into the marked destination house to load Level 2, then complete the game. No E-key interaction is required.
- The original Player movement, main.tscn, and Week 2 DeliveryHouse are preserved; the known Week 2 interaction bug remains outside this activity.

Inclusive-design reflection: Clear text labels, forgiving paths, two keyboard movement options, and unlimited untimed retries help players with different experience levels enjoy delivery at their own pace.

#### Test in Godot 4.7.2
1. Import/open project.godot and let asset imports finish.
2. Press F6 while viewing either level to test it separately, or F5 to open the Main Menu, then choose Start.
3. Move with WASD or arrow keys; touch each puddle and confirm a reset to START.
4. Check that hedges and fences block movement. Follow the path to DELIVER HERE; Level 1 should load Level 2 automatically.
5. Finish Level 2 and confirm the completion message appears and movement stops. Press F8 to stop; F5 opens the Main Menu again.

#### Source files and validation
- scenes/levels/level_1.tscn and level_2.tscn contain the saved layouts, original Player instances, START markers, hazards, goal houses, and HUD.
- resources/neighborhood.tres uses existing grass/path/bush/flower/tree/fence images; bush and fence tiles have collision polygons.
- scenes/objects/hazard.tscn and scenes/objects/goal.tscn are reusable Area2D scenes, with signal logic in scenes/objects/hazard.gd and goal.gd.
- scenes/levels/week3_level.gd handles resets, progression, and completion independently of Week 2.
- tools/build_week3.gd can explicitly regenerate the TileSet and layouts (overwrites those generated files). It never runs during gameplay.
- tools/validate_week3.gd checks saved tiles, Player reuse, all puddle overlaps, hedge collisions, progression, and completion through headless physics.

With your Godot executable on PATH, run from the project directory:

```text
godot --headless --path . --editor --import
godot --headless --path . --script tools/validate_week3.gd
```

Asset sizes: environment tiles, rabbit, and puddle are 32x32 pixels; the house is 64x64. Dirt and water tiles remain available for future levels. No new images were generated.

Validation performed with Godot 4.7.2: headless import and both scene loads completed without project parsing/resource errors; integration checks reported 0 failures. The restricted environment emitted certificate-store and editor user-directory errors. Interactive visual playtesting remains to be done.

## Week 4 - Art, Animation & Particles

The existing Player now uses AnimationPlayer to animate Sprite2D's texture. The idle animation uses char_mail_carrier_idle.png. The looping move_down, move_up, move_left, and move_right animations each use their matching char_mail_carrier_DIRECTION_1.png and _2.png frames. All nine supplied PNGs are 32x32 and live in assets/characters/. Walking uses 48 texture frames per second (one frame every 1/48 second), as requested.

The movement script selects an animation from velocity, uses the dominant axis (vertical on diagonal ties), and only changes playback when the animation name changes. Existing speed (220), movement, collision, and delivery feedback are preserved. Animations affect texture only, leaving the delivery squash/stretch tween intact.

MovementDust is a GPUParticles2D at the rabbit's feet: 10 small warm dust particles, 0.3-second lifetime, slight spread, and low drift. It emits while moving and stops emitting when idle or when completion disables movement; existing particles expire within 0.3 seconds. It uses built-in particles without an external texture.

### AI-assisted art

**AI-generated asset:** Directional walking sprites for the rabbit mail carrier, with two frames each for down, up, left, and right. The original idle sprite already existed.

**AI tool:** ChatGPT image generation.

**Prompt/process:** The original rabbit mail carrier sprite was used as a visual reference. Additional up, down, left, and right walking poses were generated in the same pixel-art style, with two walking frames per direction.

**Editing/cleanup:** The generated sprites were separated into individual PNG files, renamed consistently, and organized under the character assets folder before being integrated into the player animations. This describes the supplied asset preparation; integration verified dimensions and used these files without further image edits or new image generation.

### Testing Week 4

1. Open project.godot in Godot 4.7.2, wait for imports, then press F5 and choose Start to launch Level 1.
2. Stand still: confirm the idle sprite and no dust emission.
3. Walk down (S/down arrow), up (W/up arrow), left (A/left arrow), and right (D/right arrow); confirm the matching two-frame animation for each direction.
4. Walk along a clear path: confirm dust appears near the feet. Release movement: confirm idle returns and dust clears within 0.3 seconds.
5. Touch a puddle: confirm the rabbit returns to START. Check hedges still block movement.
6. Reach DELIVER HERE: confirm Level 2 loads automatically.
7. Repeat movement, idle, dust, and puddle tests in Level 2. Finish its goal and confirm the completion message, idle sprite, and stopped dust.
8. Press F8 to stop. In player.tscn, select AnimationPlayer to inspect the five saved animations and their texture keys. No manual setup is needed.

Automated checks (Godot executable on PATH):

```text
godot --headless --path . --editor --import
godot --headless --path . --script tools/validate_week3.gd
godot --headless --path . --script tools/validate_week4.gd
```

Headless checks verify texture tracks, directional input selection, uninterrupted playback, particle emission flags, idle/completion behavior, and the Week 3 regressions. They do not verify GPU particle appearance or replace interactive visual playtesting.

Week 4 validation results (Godot 4.7.2): all eight GDScript files passed --check-only; resource-path checks found no missing references; both level smoke tests loaded; Week 3 and Week 4 integration suites each reported 0 failures. Headless editor import completed with environment-specific user-directory/feature-profile errors, but no project parser/resource errors. GPU particle appearance and interactive play remain for manual testing.

## Week 5 - UI/UX & Audio

### HUD

Both levels instance scenes/ui/hud.tscn, a reusable CanvasLayer with a viewport-anchored header and container-based layout. It displays Level 1 / 2 or Level 2 / 2, an updating Time: MM:SS value, status text, and controls. The timer starts when gameplay begins, continues through puddles and the Level 1-to-Level 2 transition, and stops at final completion. There is no time limit or time-based penalty. Direct F6 testing of either level also starts the timer.

A small GameSession autoload stores elapsed time and owns the three audio players so time and music persist across scene changes. The Player, animations, particles, collision geometry, and tile layouts are unchanged.

### Main Menu

The startup scene is scenes/ui/main_menu.tscn. Start begins a new run at Level 1 with the timer reset; Quit stops audio and calls get_tree().quit(). Buttons support mouse and keyboard focus (Tab/arrows and Enter/Space).

- R: restart the current level, retaining elapsed run time. From completion, R retries Level 2 and resumes timing.
- Escape: return to Main Menu; timing stops there.
- Completion panel: shows Delivery Complete! and final time, with Play Again (new Level 1 run, timer reset) and Main Menu buttons.

### Audio

All audio was generated locally using Python's standard library (math, random, array, wave) and simple synthesized tones/noise, instead of downloaded third-party assets. No samples or existing songs were used. Run python tools/generate_audio.py to reproduce the three original, mono 16-bit PCM WAV files at 22050 Hz; generation is not required to play.

| Asset | Use | Length | Bus |
|---|---|---|---|
| assets/audio/music/tiny_post_theme.wav | Gentle original major-key melody; starts in the menu and loops across levels | 12 seconds | Music, -15 dB |
| assets/audio/sfx/delivery_chime.wav | Three-note chime on either goal, preserved across the level transition | 0.70 seconds | SFX, -5 dB |
| assets/audio/sfx/puddle_splash.wav | Short synthesized splash at puddle reset | 0.28 seconds | SFX, -5 dB |

The saved default_bus_layout.tres contains Master, Music, and SFX. Music and SFX send to Master. GameSession configures a forward loop across the complete music WAV before playback. Note envelopes and quiet phrase boundaries soften the loop; music is never restarted by level/menu transitions.

### Accessibility

Larger readable text uses Godot's default font: 40px menu title, 22px buttons and primary HUD values, 20px instructions/status, and 32px completion title. Cream text on dark green panels provides high contrast. Visible keyboard focus outlines help identify selected buttons. No fonts or packages were downloaded. Readability and audio balance still need manual review on the target display.

### Peer Playtest

A real 5-minute peer playtest will be conducted after implementation. This requirement and its feedback-based change are NOT complete.

Observation:
[TO BE FILLED AFTER PLAYTEST]

Change made:
[TO BE FILLED AFTER PLAYTEST]

Ask a peer to play for five minutes, including starting a run, avoiding/touching puddles, restarting, reading the timer, and finding the menu/completion controls. Record actual observations here, then apply and document one specific change based on that feedback. No observations or feedback-based changes have been invented.

### Manual testing

1. Open project.godot in Godot 4.7.2, allow imports, and press F5. Confirm Main Menu, readable Start/Quit buttons, and music. Let it play for more than 12 seconds to hear the loop.
2. Choose Start. Confirm Level 1, Time: 00:00 increasing, readable instructions, and uninterrupted music.
3. Move in four directions; check the existing animations, dust, and hedge collision. Stand still and confirm idle/dust behavior remains correct.
4. Touch a puddle: confirm reset to START, splash sound, and a timer that keeps counting.
5. Press R: confirm the current level restarts and elapsed time is retained.
6. Reach Level 1's goal: hear the delivery chime, confirm Level 2 loads, and check that timer/music continue.
7. In Level 2, test movement, dust, puddles, and R again. Complete the goal: hear the chime, see the centered completion panel, and confirm the final time stops changing.
8. Choose Play Again: confirm Level 1 and a reset timer. Press Escape: confirm Main Menu. Start again and verify a fresh timer.
9. Complete another run and test the completion panel's Main Menu button. Test Tab/Enter navigation and resize the window to check text and panel layout.
10. Choose Quit: confirm the game closes. Use the Audio dock to inspect Master/Music/SFX if desired; no manual configuration is needed.
11. Conduct the separate five-minute peer playtest, fill the placeholders, and provide the genuine feedback before marking that activity complete.

### Technical validation

Run from the project directory with Godot on PATH:

```text
godot --headless --path . --editor --import
godot --headless --path . --script tools/validate_project.gd
godot --headless --path . --script tools/validate_week3.gd
godot --headless --path . --script tools/validate_week4.gd
godot --headless --path . --script tools/validate_week5.gd
```

The Week 5 suite exercises menu buttons, R/Escape input events, timer updates/persistence/freeze, header bounds, audio playing states/loop configuration/buses, real hazard/goal overlaps, both completion buttons, and Quit. Headless playback-state tests do not establish audible quality, visual appearance, or peer feedback.

Validation performed with Godot 4.7.2: project-aware validation loaded all 26 script/scene/resource files with zero failures; Week 3, Week 4, and Week 5 integration suites each reported zero failures and clean shutdown. The music playback-state check waited through a full 12-second loop. All referenced paths exist, git diff --check passed, and the Player files, TileSet, and saved tile data remain unchanged. The standalone --check-only command does not initialize autoload names, so validate_project.gd performs the full script/resource check in project context. Headless editor import reports only environment-specific user-directory/feature-profile errors. No interactive visual test, listening assessment, or peer playtest has been performed.

## Week 6 - AI & Enemies

One reusable crow placeholder was added to **Level 2 only**. Its colored Polygon2D body, wing, beak, and eye use no downloaded assets. A PATROL/CHASE label makes its current behavior visible. Level 1 remains the easier introduction. The Player files, directional animations, particles, input mappings, TileSet, and saved tile layouts were not changed.

### Enemy scene and FSM

scenes/enemies/enemy.tscn contains a CharacterBody2D, simple polygon visuals, a CircleShape2D body collider, NavigationAgent2D, DetectionArea with a circular collider, ContactArea with a small contact collider, and StateLabel.

The enum-based finite state machine has exactly two states:

- **PATROL:** starts at EnemyPatrolPointA (432, 400), walks to EnemyPatrolPointB (656, 224), then alternates between these two fixed markers. Patrol speed is 70 pixels/second.
- **CHASE:** DetectionArea body_entered stores the existing Player and switches state. The navigation target follows the Player, refreshed every 0.15 seconds, at 140 pixels/second. DetectionArea body_exited clears that reference and returns to PATROL. Both speeds are slower than the rabbit's unchanged 220 pixels/second.

Detection radius is 112 pixels. Detection is proximity-based, so it can notice a rabbit across a nearby hedge; navigation still takes the walkable route around that hedge. No random wandering, health, combat, attacks, or additional enemy types were added.

### Navigation

Level 2 contains a NavigationRegion2D using the saved resources/level_2_navigation.tres. The polygon is baked from existing Ground path tiles (source ID 1), with all five visible puddles excluded and 12 pixels of clearance for the crow's 10-pixel body radius. The patrol points are on opposite sides of a bend. The crow sets NavigationAgent2D.target_position and moves toward get_next_path_position(), rather than moving directly through obstacles toward the player. It waits for the navigation map's first synchronization before requesting a path.

No manual baking is required. tools/build_week6_navigation.gd can explicitly rebuild only this navigation resource after path/puddle edits:

```text
godot --headless --path . --script tools/build_week6_navigation.gd
```

The older tools/build_week3.gd also preserves the enemy/marker/region setup if deliberately used to regenerate levels; it was not run during Week 6. Re-bake navigation after changing generated walkable geometry.

### Contact consequence

Physical body contact or the small ContactArea touching the Player emits player_touched. The level uses the same guarded, deferred reset flow as puddles: teleport the rabbit to the existing Start marker, clear velocity, play the existing reset sound, and show a crow-specific HUD message. There is no loss of health or elapsed time. After either a puddle or crow reset, the crow returns to its original patrol position and clears its chase target, keeping START safe. The crow stops moving/detecting on completion; R recreates one fresh enemy and Escape removes it with the level.

### AI-assisted coding

**AI-drafted with Codex:**
- Initial enemy FSM structure.
- Patrol/chase state transitions.
- NavigationAgent2D movement logic.

**Reviewed/adjusted by Codex for this implementation:**
- Actual Tiny Post scene/resource paths and the existing week3_player group.
- Patrol markers on the Level 2 bend.
- Detection radius (112), patrol speed (70), and chase speed (140).
- Navigation clearance, map synchronization, puddle exclusions, and chase target refresh timing.
- Contact/reset integration with the existing Start marker, HUD, timer, sound, and completion flow.
- Regression compatibility with the existing Tiny Post scenes and saved level generator.

Understanding notes: the state selects the goal and speed; Area2D signals select the state; NavigationAgent2D supplies the next safe path point; move_and_slide applies the movement and body collisions. Resetting is deferred because detection/contact signals occur during physics processing. Comments in enemy.gd explain these responsibilities. These notes describe the implemented code and automated checks, not manual edits, student review, or visual playtesting that has not occurred.

### Validation

With Godot on PATH, run:

```text
godot --headless --path . --editor --import
godot --headless --path . --script tools/validate_project.gd
godot --headless --path . --script tools/validate_week3.gd
godot --headless --path . --script tools/validate_week4.gd
godot --headless --path . --script tools/validate_week5.gd
godot --headless --path . --script tools/validate_week6.gd
```

The Week 6 suite runs real physics/navigation: it observes a full patrol there and back, checks path points around the bend, verifies movement stays on walkable tiles and clear of puddles, detects Player entry/exit, refreshes a moving chase target, follows a puddle detour, triggers contact reset/audio, stops the enemy on completion, and verifies restart/menu cleanup. Headless checks inspect visible geometry and collision setup, but do not establish actual visual appearance or difficulty balance.

### Manual testing

1. Open project.godot in Godot 4.7.2, allow imports, press F5, and choose Start. Finish Level 1 normally. Confirm its movement, animations, dust, puddles, HUD, music, and transition are unchanged.
2. In Level 2, wait at START and watch the purple crow on the middle/right bend. Allow about 12 seconds to see it visit both patrol points; its label should say PATROL. For faster testing, open scenes/levels/level_2.tscn and press F6.
3. Follow the path toward the crow. When nearby, check that its label changes to CHASE and that it follows you using the paths. Move away (the rabbit is faster) until outside detection, then check that the label returns to PATROL.
4. Lead it near the central puddle and bend; confirm it routes around puddles/hedges rather than cutting through them. Optionally enable Debug > Visible Navigation and Visible Collision Shapes before running to inspect the region and detection/contact shapes.
5. Touch the crow: confirm the rabbit returns to START, a reset sound plays, the HUD explains the reset, the timer continues, and the crow returns to its patrol start. Touch a puddle and confirm its existing reset still works.
6. Press R and confirm one enemy starts patrolling again. Press Escape and confirm Main Menu; Start should begin a fresh Level 1 run.
7. Finish Level 2 while avoiding the crow. Confirm the completion panel, stopped timer/player/enemy, Play Again, and Main Menu buttons still work.

Interactive visual testing and difficulty assessment remain for the user's review. No peer playtest feedback or results have been invented; earlier pending playtest fields are preserved.

Week 6 validation performed with Godot 4.7.2: all 31 project scripts/scenes/resources loaded successfully; Week 3, 4, 5, and 6 integration suites each reported 0 failures. The Week 6 test observed two patrol target switches at normal physics timing. No missing resource references were found and git diff --check passed. Player files, project settings/inputs, Level 1, existing UI/session scripts, TileSet, and Level 2 tile data remain unchanged. Headless editor import completed with only the environment-specific user-directory/feature-profile errors already seen in earlier weeks. No interactive visual gameplay test was performed.
