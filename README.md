# Bio Protocol: Entropy Zone

中文暂定名：《生化协议：熵区》。

A Steam-focused 2D pixel-art, top-down room-based action roguelite prototype set inside Abyss Island's sealed underground complex, a corporate bioengineering site swallowed by the entropy zone.

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
- `docs/前期故事梗概与人物信息.md`
- `docs/角色设定.md`
- `docs/状态效果系统.md`

This project is currently based on Quiver's Tiny Wizard Demo and Top-Down Shooter Core. See `LICENSES/THIRD_PARTY_NOTICES.md` for source and license details.

## Current Playable Subjects

- Tiemu / Iron Curtain: a stable adaptive strain built to hold the line. High HP, slower movement, starts with the Laser Pointer, can trigger Iron Curtain Protocol, and passively absorbs 1 incoming damage every 5 seconds.
- Liuying / Shadow: a neural-reflex subject tuned for high-speed flanks and risky repositioning. Low HP, very high movement speed, starts with the Containment Nailgun, has a 15% dodge chance, and gains faster attacks after dodging or using Phase Assault.
- Huisheng / Echo: a resonance subject tuned for energy-control experiments. Medium HP, balanced movement, starts with the Energy Saber, can trigger Echo Pulse, and restores energy from weapon hits.

## Current Prototype Controls

- Start run: choose Tiemu, Liuying, or Huisheng on the opening screen; the selected adaptive subject wakes from a pod in the Sealing Protocol Wake Bay
- Move: WASD
- Aim: mouse
- Primary fire: left mouse button
- Legacy directional fire: arrow keys
- Plant Breach Charge: E
- Character skill: Q
- Secondary fire: right mouse button
- Switch MVP weapons: 1 / 2 / 3 / 4 after pickup
- Reserved dash: Space
- Interact / pick up weapon stand item: F

## Current Weapon Prototype

The player now equips a new MVP weapon slot at startup. Press `1`, `2`, or `3` to switch between the current MVP weapons:

- Tiemu starts with the Laser Pointer, 8 HP, steadier but slower movement, and Stabilized Plating that absorbs 1 incoming damage every 5 seconds.
- Liuying starts with the Containment Nailgun, 5 HP, very high movement speed, a 15% dodge chance, decoy afterimages, an independent movement momentum passive, and Ghost Tempo after dodging or dashing.
- Huisheng starts with the Energy Saber, 6 HP, high energy capacity, and Resonance Return that restores energy from weapon hits.
- `1` Starting ranged weapon: hold or press the left mouse button to attack toward the mouse cursor.
- `2` Energy Saber: press or hold left mouse button to swing a short-range blade with a visible slash arc.
- `3` Power Gauntlets: left mouse button lunges into a short punch, right mouse button fires a ranged energy bolt from the lower muzzle.
- `4` Quarantine Blade: unlocked by picking up Raven's quarantine blade from the starter weapon stand in the Sealing Protocol Wake Bay.
- Beam, melee, and projectile weapons all route damage through targets that expose the inherited `hit()` method.
- The old Tiny Wizard arrow shooter is kept in the player scene for compatibility, but hidden and disconnected from primary fire.

## Current Skill Prototype

Each subject now has an energy resource and one active skill on `Q`. The HUD shows the current skill, energy, and readiness state:

- Tiemu - Iron Curtain Protocol: costs 40 energy, gains temporary shield, reduces incoming damage, and emits a short defensive pulse.
- Liuying - Phase Assault: costs 30 energy, has 2 charges, dashes through enemies, deals reduced weapon-based damage, applies Vulnerable for 3 seconds, and briefly avoids damage during the dash. Liuying also leaves short blue afterimages while moving; nearby red and black fly enemies prefer those afterimages as temporary decoy targets.
- Huisheng - Echo Pulse: costs 35 energy and emits a resonance wave that damages nearby enemies and slows affected specimens.

Current core passives:

- Tiemu - Stabilized Plating: every 5 seconds, automatically absorbs 1 incoming damage.
- Liuying - Ghost Tempo: dodging or using Phase Assault gives 2 seconds of faster weapon rhythm.
- Huisheng - Resonance Return: weapon hits restore a small amount of energy on a short cooldown.

The current energy system is a foundation for later character-specific skill pools. Upgrade selection, skill mutations, and energy-spending build choices are not implemented yet.

## Current Status Effect Prototype

The prototype now has a reusable status effect controller at `res://tiny_wizard/status_effects/status_effect_controller.gd`.

- Vulnerable: used by Liuying's Phase Assault, increases damage taken and shows an orange status ring.
- Slow: used by Huisheng's Echo Pulse, temporarily reduces movement speed and shows a purple status ring.
- Damage over time: foundation is available for future corrosion, poison, burning, and Shitong-style contamination effects.

## Current Dungeon Prototype

The current flow starts with a 5-room Sealing Protocol wake sequence, then enters a randomized 8-room sealed sector.

Wake sequence:

- Sealing Protocol Wake Bay: subject selection and sleep pods
- Target Sync Range: functional TARGET A/B/C/D shooting targets that unlock the right door when all targets are online
- Raven Armory Annex: Raven guidance and the Quarantine Blade weapon stand
- Breach Charge Training Lab: guarded cache, Breach Charge, quarantine-resin reward chest
- A-03 Recovery Chamber: Failed Subject A-03 encounter and Descent Rift exit

Formal sector room roles:

- Sealing Airlock: formal run spawn room
- Sealed Specimen Wards: combat rooms that lock until enemies are cleared
- Evidence Vaults: guarded reward rooms
- Raven Armory Cache: random weapon pickup room
- Raven Quarantine Shop: fixed pre-boss merchant room with Raven's armory terminal and story guidance
- A-03 Recovery Chamber: sector boss room for Failed Subject A-03: Breach Husk, with a named health bar, charge pursuit, green poison volleys, low-health summons, and a Descent Rift exit

Combat rooms close their visible doors when entered and reopen them after all enemies are defeated. Hidden doors remain locked, so the player cannot leave the generated layout through missing room exits.

Neutralized specimens can now drop Protomatter Fragments, the in-game resource for 原质碎片. A-03-class enemies always drop several fragments, burst green blood on death, and open the Descent Rift after defeat. Fragments are collected into the inventory, shown in the resource UI, and used as Raven's current weapon-trade currency. Later versions can also spend them on permanent upgrades or story unlocks.

Raven currently appears in a dedicated safehouse immediately before the formal sector boss. Press `F` near Raven to open the armory panel, then press `F` again to buy the offered unowned weapon for Protomatter Fragments. The current offer is also shown as a weapon preview on Raven's counter. Supply purchases and random temporary black markets are reserved for later versions.

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
