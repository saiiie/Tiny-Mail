# Tiny Post

Tiny Post is a small top-down 2D game created in Godot for my Game Development weekly activities.

The player controls a rabbit mail carrier who travels through a neighborhood, avoids hazards and enemies, and reaches delivery destinations. The project was developed incrementally across eight weeks, with each activity introducing a new game development concept.

## Controls

| Input | Action |
| --- | --- |
| W / Up Arrow | Move Up |
| S / Down Arrow | Move Down |
| A / Left Arrow | Move Left |
| D / Right Arrow | Move Right |
| R | Restart |
| Esc | Return to Main Menu |

> Update this table if the final project's actual controls differ.

## Built With

- Godot 4.7.2
- GDScript
- Git and GitHub
- Codex for AI-assisted programming
- ChatGPT image generation for AI-assisted sprite creation

---

# Development Log

## Week 1 - Project Setup

The initial Tiny Post project was created as a simple 2D Godot game.

### Implemented

- Created the Godot project and initial scene.
- Added the rabbit mail carrier as the main character.
- Set up the basic project structure.
- Initialized the Git repository.
- Connected the project to a private GitHub repository.
- Configured `.gitignore` and Git LFS where required.

The goal of the first version was to establish the project and display the game's main character in a working 2D scene.

---

## Week 2 - Player Movement & Interaction

Player-controlled movement and basic interaction were introduced.

### Implemented

- Created a reusable `Player` scene.
- Used `CharacterBody2D` for player movement.
- Added keyboard movement.
- Added player collision.
- Created a delivery house interaction.
- Added proximity/delivery feedback.

The player can move around the environment and interact with a delivery destination.

---

## Week 3 - Level Design & Difficulty Curve

The game was expanded into a two-level playable experience.

### Implemented

- Created Level 1 and Level 2.
- Built environments using `TileMapLayer` and TileSet resources.
- Added starting positions and delivery destinations.
- Added puddle hazards.
- Touching a puddle resets the player to the level's start.
- Added Level 1 → Level 2 progression.
- Increased the number and placement difficulty of hazards in Level 2.

### Difficulty Curve

**Level 1**
- Wider and simpler routes.
- Fewer puddle hazards.
- Introduces the game's basic challenge.

**Level 2**
- More hazards.
- More turns and restricted movement areas.
- Requires more careful navigation.

### Inclusive Design

The environments use simple, neutral visuals and clearly distinguishable paths and hazards to keep the game readable and welcoming without relying on harmful cultural stereotypes.

---

## Week 4 - Art, Animation & Particles

The player's visual feedback was improved through directional animation and particle effects.

### Player Animation

`AnimationPlayer` is used to control the rabbit's animations.

Implemented animation states include:

- Idle
- Move Down
- Move Up
- Move Left
- Move Right

Each movement direction uses two alternating walking frames. The player's movement script automatically chooses the appropriate animation based on movement direction.

### Particle Effect

Movement particles were added to provide additional visual feedback while the player is walking.

### AI-Assisted Art

**AI-generated asset:** Directional walking sprites for the rabbit mail carrier

**AI tool:** ChatGPT image generation

**Process:**  
The original rabbit mail carrier sprite was used as the visual reference. Additional up, down, left, and right walking poses were generated in the same pixel-art style, with two walking frames created for each direction.

**Editing performed:**  
The generated sprite images were separated into individual PNG files, cleaned up as needed, consistently renamed, and organized inside the character assets directory before being integrated into the player's animations.

---

## Week 5 - UI/UX & Audio

User interface, audio, and accessibility features were added to create a more complete game experience.

### HUD

A `CanvasLayer`-based HUD was added to keep gameplay information visible independently of the game world.

The HUD includes:

- Gameplay timer.
- Level information where applicable.

### Main Menu

The game includes a main menu with:

- Start
- Quit

The game also provides functionality for restarting gameplay or returning to the main menu.

### Audio

Tiny Post uses separate audio buses for:

- `Music`
- `SFX`

Audio includes:

- Background music.
- Delivery/goal sound effect.
- Hazard sound effect where applicable.

The audio assets were generated locally as simple original synthesized sounds rather than downloaded third-party audio.

### Accessibility

Larger and readable interface text is used throughout the HUD, menus, and completion UI. Text and interface elements use clear contrast to improve readability.

---

## Week 6 - AI & Enemies

An AI-controlled enemy was introduced to add a moving challenge to the game.

### Enemy AI

The enemy uses:

- `CharacterBody2D`
- `NavigationAgent2D`
- `Area2D` player detection
- Finite State Machine (FSM)

### Enemy States

**PATROL**

The enemy moves between predefined patrol points while the player is outside its detection range.

**CHASE**

When the player enters the enemy's detection area, the enemy switches to the chase state and uses navigation/pathfinding to pursue the player.

When the player leaves the detection area, the enemy returns to patrol behavior.

Contact with the enemy resets the player to the level's starting point.

### AI-Assisted Coding

Codex was used as a pair-programming assistant to draft the initial:

- FSM structure.
- Patrol/chase transitions.
- `NavigationAgent2D` movement logic.

The generated implementation was reviewed and adapted to the existing Tiny Post project, including scene references, movement speeds, detection behavior, patrol points, and player-reset behavior.

---

## Week 7 - Juice, Save/Load & Optimization

Additional game feel, persistent progress, and performance improvements were introduced.

### Polish

Gameplay feedback includes:

- Screen shake on player impact.
- Brief hit-stop on impact.
- Tweened UI feedback.

These effects provide clearer feedback when the player interacts with hazards, enemies, or delivery objectives.

### Save / Load

Tiny Post includes persistent game progress.

The save system stores its data under Godot's `user://` directory so that saved progress persists between sessions.

Saved information includes the player's current game progression, allowing the game to determine which level should be restored.

### Continue

The Main Menu includes a **Continue** option when valid saved progress exists.

Typical flow:

Start → Level 1 → Complete Level 1 → Save → Level 2

After reopening the game:

Main Menu → Continue → Restore Saved Progress

Invalid or missing save data is handled safely without preventing the player from starting a new game.

### Optimization

**Optimization implemented:**  
[DESCRIBE THE ACTUAL OPTIMIZATION IMPLEMENTED]

Example if applicable:

> Enemy navigation target updates were reduced so that pathfinding targets are not unnecessarily recalculated every physics frame.

### Profiling

Godot's Profiler was used to inspect runtime performance.

---

## Week 8 - Multi-Platform Export & Team Git

The final activity focuses on preparing Tiny Post for multiple platforms and practicing collaborative Git workflows.

### Target Platforms

Tiny Post is configured for:

- Windows Desktop
- Web

### Export Builds

**Windows**

`builds/windows/TinyPost.exe`

**Web**

`builds/web/index.html`

### Platform-Specific Tweak

The Web version uses browser-friendly window/stretch behavior so that the game area and interface remain readable when displayed at different browser window sizes.

### Team Git Practice

Although Tiny Post is an individual project, the Week 8 activity includes a simulated collaborative Git workflow to practice techniques that would normally be used in a team repository.

The exercise includes:
- Creating a feature branch.
- Making an isolated change.
- Opening a pull request.
- Creating a controlled merge conflict in `README.md`.
- Resolving the merge conflict.
- Merging the completed work.

This exercise is performed individually for practice and does not represent contributions from another developer.

---

# Project Structure

```text
tiny-post/
├── assets/
│   ├── audio/
│   ├── characters/
│   ├── hazards/
│   ├── objects/
│   └── tiles/
│
├── resources/
│
├── scenes/
│   ├── enemies/
│   ├── levels/
│   ├── objects/
│   ├── player/
│   └── ui/
│
├── scripts/
├── tools/
├── builds/
├── project.godot
└── README.md