# Bio Protocol: Entropy Zone

中文暂定名：《生化协议：熵区》。

A Steam-focused 2D pixel-art, top-down room-based action roguelite prototype set inside the Abyss Facility, a corporate bioengineering complex swallowed by the entropy zone.

Current design direction:

- Theme: bio-horror, corporate conspiracy, alien protomatter, adaptive test subjects
- Core loop: enter room, clear enemies, pick up weapons, build a run, die, restart
- Engine: Godot 4
- MVP weapons:
  - Laser Pointer
  - Energy Saber
  - Power Gauntlets

Story and worldbuilding baseline:

- `docs/剧情设定_生化协议_熵区.md`

This project is currently based on Quiver's Tiny Wizard Demo and Top-Down Shooter Core. See `LICENSES/THIRD_PARTY_NOTICES.md` for source and license details.

## Current Playable Subjects

- Panshi / Bulwark: a stable adaptive strain built to hold the line. High HP, slower movement, starts with the Laser Pointer.
- Liuying / Reflex: a neural-reflex subject tuned for fast repositioning and room clears. Low HP, high movement speed, starts with the Containment Nailgun.
- Huisheng / Echo: a resonance subject reserved for the future energy-skill branch. Medium HP, balanced movement, starts with the Energy Saber.

## Current Prototype Controls

- Start run: choose Panshi, Liuying, or Huisheng on the opening screen; the selected adaptive subject wakes from a cryo pod in the Cryo Wake Bay
- Move: WASD
- Aim: mouse
- Primary fire: left mouse button
- Legacy directional fire: arrow keys
- Plant Breach Charge: E
- Secondary fire: right mouse button
- Switch MVP weapons: 1 / 2 / 3 / 4 after pickup
- Reserved dash: Space
- Interact / pick up weapon stand item: F

## Current Weapon Prototype

The player now equips a new MVP weapon slot at startup. Press `1`, `2`, or `3` to switch between the current MVP weapons:

- Panshi starts with the Laser Pointer, 8 HP, and steadier but slower movement.
- Liuying starts with the Containment Nailgun, 5 HP, and faster movement.
- Huisheng starts with the Energy Saber, 6 HP, and balanced movement as the future energy-skill subject.
- `1` Starting ranged weapon: hold or press the left mouse button to attack toward the mouse cursor.
- `2` Energy Saber: press or hold left mouse button to swing a short-range blade with a visible slash arc.
- `3` Power Gauntlets: left mouse button lunges into a short punch, right mouse button fires a ranged energy bolt from the lower muzzle.
- `4` Test Sword: unlocked by picking up Raven's test blade from the starter weapon stand in the Cryo Wake Bay.
- Beam, melee, and projectile weapons all route damage through targets that expose the inherited `hit()` method.
- The old Tiny Wizard arrow shooter is kept in the player scene for compatibility, but hidden and disconnected from primary fire.

## Current Dungeon Prototype

The current flow starts with a 3-room wake sequence, then enters a randomized 8-room Abyss Facility sector.

Wake sequence:

- Cryo Wake Bay: subject selection, cryo pods, starter weapon stand
- Breach Training Lab: guarded cache, Breach Charge, resin-sealed reward chest
- Low-Grade Fusion Chamber: tutorial Fusion encounter and Entropy Rift exit

Formal sector room roles:

- Safehouse Airlock: formal run spawn room
- Specimen Cells: combat rooms that lock until enemies are cleared
- Data Vaults: guarded reward rooms
- Raven Cache: random weapon pickup room
- Raven Safehouse: fixed pre-boss merchant room with Raven's armory terminal and story guidance
- Fusion Node: sector boss room with an Entropy Rift exit

Combat rooms close their visible doors when entered and reopen them after all enemies are defeated. Hidden doors remain locked, so the player cannot leave the generated layout through missing room exits.

Neutralized specimens can now drop Protomatter Fragments. Fusion-class enemies always drop several fragments. For now, fragments are collected into the inventory and shown in the resource UI; later versions can spend them in Raven's shop, permanent upgrades, or story unlocks.

Raven currently appears in a dedicated safehouse immediately before the formal sector boss. Press `F` near Raven to open the armory panel, then press `F` again to buy the offered unowned weapon for Research Data. Supply purchases and random temporary black markets are reserved for later versions.

Breach Charges are planted with `E` when the Breach Charge count is above zero. After a short fuse, they destroy nearby destructible resin-rock tiles, including stones blocking reward pickups.

For now, player death immediately restores health and respawns the subject in the current run's start room instead of ending the run.

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
