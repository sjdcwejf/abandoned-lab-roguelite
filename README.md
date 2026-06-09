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

- Start run: choose Experimenter or Containment Technician on the opening screen; the selected character wakes from their sleep pod in the start room
- Move: WASD
- Aim: mouse
- Primary fire: left mouse button
- Legacy directional fire: arrow keys
- Bomb/use inherited prototype item: E
- Secondary fire: right mouse button
- Switch MVP weapons: 1 / 2 / 3 / 4 after pickup
- Reserved dash: Space
- Interact / pick up weapon stand item: F

## Current Weapon Prototype

The player now equips a new MVP weapon slot at startup. Press `1`, `2`, or `3` to switch between the current MVP weapons:

- Experimenter starts with the Laser Pointer.
- Containment Technician starts with the Containment Nailgun.
- `1` Starting ranged weapon: hold or press the left mouse button to attack toward the mouse cursor.
- `2` Energy Saber: press or hold left mouse button to swing a short-range blade with a visible slash arc.
- `3` Power Gauntlets: left mouse button lunges into a short punch, right mouse button fires a ranged energy bolt from the lower muzzle.
- `4` Test Sword: unlocked by picking up the sword from the starter weapon stand in the start room.
- Beam, melee, and projectile weapons all route damage through targets that expose the inherited `hit()` method.
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

For now, player death immediately restores health and respawns the character in the start room instead of ending the run.

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
