# Cop Code Reference - From Steam Push

This document references the cop code from the Steam Push (commit 83c0d78 - "added push to talk event, not actually implemented", dated Sept 21, 2025).

## Overview

The cop system in Code for Cause includes AI-controlled police vehicles that pursue the player when they are detected. The cop code consists of two main components:

### 1. Deprecated Cop Follow System (`Deprecated/cop_follow.gd`)

**Location:** `/Deprecated/cop_follow.gd`

**Purpose:** Controls cop car movement along road paths using PathFollow3D

**Key Features:**
- Extends PathFollow3D for path-based movement
- Configurable speed (export var)
- Ground alignment using raycasts
- Automatic path switching when reaching end of current path
- Finds and assigns to nearest path dynamically

**Main Functions:**
- `_ready()`: Sets mesh to top-level positioning
- `_process(delta)`: Handles collision detection and path progression
- `align_with_ground()`: Aligns mesh with ground normal using raycasts
- `assign_to_nearest_path()`: Switches to nearest road path
- `find_nearest_path()`: Locates closest path from "road_path" group

### 2. Active Cop Cosmetic System (`Scenes/Inheritance/Cop/CopCosmetic.gd`)

**Location:** `/Scenes/Inheritance/Cop/CopCosmetic.gd`

**Purpose:** Handles cop car visual and audio effects (sirens, lights, voice lines)

**Key Features:**
- Extends BaseCosmetic class
- Siren audio system
- Police voice announcements ("Pull Over", "Best Driver")
- Emergency light toggling (red/blue)
- Headlight intensity control
- Distance-based activation (hunt_dist threshold)

**Exported Variables:**
- `siren`: AudioStreamPlayer3D for siren sounds
- `talk`: AudioStreamPlayer3D for voice lines
- `chassis`: MeshInstance3D for light control
- `talk_chance`: 0-100% chance of announcing
- `talk_timer`: Timer for announcement intervals

**Main Functions:**
- `context_ready()`: Initializes connections and validates car reference
- `context_process(_delta)`: Activates sirens/lights when player in range
- `toggle_colors()`: Alternates between red and blue emergency lights
- `announce()`: Randomly plays voice lines when chasing player

**Light System:**
- Toggles between red (material 4) and blue (material 6) emissions
- Headlight energy: 7.0 when active, 5.0 when inactive
- Uses StandardMaterial3D emission properties

### 3. Cop Scene Files

The cop system includes three scene variants:
- **RecklessCop.tscn**: Aggressive pursuit behavior
- **Safe Cop.tscn**: Conservative pursuit behavior  
- **Super Cop.tscn**: Enhanced pursuit capabilities

All scenes are located in `/Scenes/Inheritance/Cop/`

### Related Files from Steam Push

Additional cop-related assets added in the steam push:
- `/Assets/Models/Cop Car/The__Cop_Car2.glb` - 3D cop car model
- `/Assets/Models/Cop Car/The__Cop_Car2_*.png` - Cop car textures (seats, wheels)
- `/Assets/Models/Car/Cop_Detector.glb` - Detection mesh/trigger

## Implementation Notes

1. The deprecated `cop_follow.gd` system uses Godot's PathFollow3D for movement
2. The active `CopCosmetic.gd` system integrates with the BaseDriver class
3. Detection triggers the global `Globals.detected = true` flag
4. Voice lines are accessed through `Globals.world_voice_lines` dictionary
5. The system uses distance checking (`dist_to_target` vs `hunt_dist`) for activation

## Git History

- **Commit:** 83c0d78b175c48637caa812df711331c5c06abbc
- **Date:** Sun Sep 21 12:03:21 2025 -0400
- **Message:** "added push to talk event, not actually implemented"
- **Author:** 45DegreeAngl

This was the initial commit that introduced the entire project including the cop system.
