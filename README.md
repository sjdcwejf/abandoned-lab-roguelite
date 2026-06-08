# Abandoned Lab Roguelite

A Steam-focused 2D pixel-art, top-down room-based action roguelite prototype.

Current design direction:

- Theme: abandoned laboratory
- Core loop: enter room, clear enemies, pick up weapons, build a run, die, restart
- Engine: Godot 4
- MVP weapons:
  - Laser Pointer
  - Energy Saber
  - Power Gauntlets

This project is currently based on Quiver's Tiny Wizard Demo and Top-Down Shooter Core. See `LICENSES/THIRD_PARTY_NOTICES.md` for source and license details.

## Current Prototype Controls

- Move: WASD
- Aim: mouse
- Primary fire: left mouse button
- Legacy directional fire: arrow keys
- Bomb/use inherited prototype item: E
- Reserved secondary fire: right mouse button
- Reserved dash: Space
- Reserved interact: F

## Current Weapon Prototype

The player now equips a new MVP weapon slot at startup. Its first weapon is `Laser Pointer`:

- Hold the left mouse button to fire a continuous beam toward the mouse cursor.
- The beam uses a raycast, stops on collision, and applies repeated damage to targets that expose the inherited `hit()` method.
- The old Tiny Wizard arrow shooter is kept in the player scene for compatibility, but hidden and disconnected from primary fire.

## Current Dungeon Prototype

The main scene now generates a fixed 7-room abandoned lab layout at runtime:

- `(0, 0)`: Start Room
- `(1, 0)`: Monster Room A
- `(2, 0)`: Monster Room B
- `(3, 0)`: Boss Room
- `(1, -1)`: Weapon Room
- `(2, -1)`: Reward Room A, guarded and with an unobstructed chest containing a bomb
- `(2, 1)`: Reward Room B, guarded reward chest

Combat rooms close their visible doors when entered and reopen them after all enemies are defeated. Hidden doors remain locked, so the player cannot leave the generated layout through missing room exits.

Bombs are used with `E` when the bomb inventory count is above zero. After a short fuse, bombs now destroy nearby destructible rock tiles, including the stones blocking the current weapon-room pickup.

## Open In Godot

Import this file in Godot 4:

```text
/Users/tianyisongdemacbook/Documents/个人项目/abandoned-lab-roguelite/project.godot
```

The current main scene remains:

```text
res://tiny_wizard/main.tscn
```

The `tiny_wizard` directory name is intentionally kept during the first migration step so the inherited scene paths continue to load. It can be renamed after the project is stable.
