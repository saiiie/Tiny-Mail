# Tiny Mail

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
