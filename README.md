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
2. Press F6 while viewing either level to test it separately, or F5 to start Level 1.
3. Move with WASD or arrow keys; touch each puddle and confirm a reset to START.
4. Check that hedges and fences block movement. Follow the path to DELIVER HERE; Level 1 should load Level 2 automatically.
5. Finish Level 2 and confirm the completion message appears and movement stops. Press F8 to stop; F5 starts again.

#### Source files and validation
- scenes/levels/level_1.tscn and level_2.tscn contain the saved layouts, original Player instances, START markers, hazards, goal houses, and HUD.
- resources/neighborhood.tres uses existing grass/path/bush/flower/tree/fence images; bush and fence tiles have collision polygons.
- hazard.tscn and scenes/objects/goal.tscn are reusable Area2D scenes, with signal logic in scenes/objects/hazard.gd and goal.gd.
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
