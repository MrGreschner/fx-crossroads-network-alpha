# v45 — Rook Ironhand

Hero 28 is **Rook Ironhand**, a free human chain fighter with original idle, walking and attack pixel art. He has 125 health and 230 movement speed.

| Ability | Behavior and balance |
| --- | --- |
| Chain Sweep — primary | A flail extends, swings through a 120-degree arc, then retracts. 210 reach, 22 damage once per enemy, 0.9-second cooldown. Alternates swing direction. Damage follows the visible moving head, rather than a full-circle hit. |
| Grapnel Rush — secondary, level 3 | The hook travels first, then pulls Rook forward over time, up to 260 units. 18 damage once per enemy crossed, 0.6-second stun, 6-second cooldown. Walls stop movement. Does not grant invulnerability. |
| Follow Through — passive, level 5 | A Grapnel Rush that hits arms one bonus: the next Chain Sweep within four seconds gains 8 damage. A missed rush earns no bonus. |
| Iron Haul — special, level 6 | A chain extends along a marked 430-unit lane, catches up to four enemies for 12 damage and a short slow, then pulls them back and deals 38 return damage. 18-second cooldown. Bosses take damage but cannot be displaced. PvP players are pulled at half speed. |

Quarantine Medic and Star Navigator now appear immediately after Emberwright in the town Character Hall and multiplayer hero selection. Young Ram remains first. All v44 school realms and earlier content remain.

## Student expansion

The shared engine now supports `chain_sweep`, `grapnel_rush`, and `iron_haul`. Copy `content/characters/rook.json` as an example; use `ABILITY_CATALOG.md` for fields. `scripts/chain_combat.gd` handles authoritative hits, movement, visuals and co-op snapshots. `tools/build_rook.py` regenerates Rook's data, art and requested roster order; it overwrites direct edits to those generated files.

## Verification and installation

Godot 4.5.1 checks cover per-swing hit limits, alternating arcs, grapnel timing and walls, passive consumption, haul target cap, boss resistance, interruption on death/stun, co-op snapshots and control release, plus friendly-fire and PvP behavior. School solo/co-op, expert content, quests and Gate Defence regression checks passed. Character Hall text, roster order and in-game chain visuals were rendered and inspected.

Physical-phone performance and live browser networking remain deployment playtests. Extract the editable project, open `project.godot`, let Godot import assets and press F5. Export a fresh Web ZIP for itch.io; this source ZIP is not the Web export. No Render changes are needed. Use the same build for everyone in a multiplayer session.
