# v40 — Moonburrow Hollow and requested fixes

- Rune Duelist's Runestep returns to the oldest of its three runes, up to 480 units along a clear route. It uses the existing forward-step fallback if that first rune cannot be reached.
- Nera Lockstep's Latchline stun increases from 0.45 to 1.5 seconds. Its selection description and student ability sheet now match.
- Fixed Brasslock solo door interaction: the run handler now passes E / touch Interact to the city controller. Prompts explicitly show Open / Close door. Existing co-op interaction remains available.
- Renamed Elara to Prism Mage and Bracken to Bracken of Moonburrow. IDs, sprites and saved hero selections remain compatible.
- Moonburrow Hollow is a new medium realm after Folded Coast. Three surface regions contain distinct camp, rootwell and ruined moonstone landmarks. Ravines have bridges; four marked entrances lead into connected underground warrens, side passages and an ancestral boss crypt. Surface and underground contain visible proximity mines with warning time before their blasts.
- Six original enemy species: burrowing melee Burrowfang; burrowing ranged Shardspitter; mine-laying Fusehare; root-wave Rootwarden; returning-projectile Echo Bat; healing/poison Sap Nurse. Every species has original sprite poses and a different combat pattern. Underground movers show animated soil rustles while protected, then emerge to attack.
- Flintroot, the Warren King, is a 1,250-HP ancestral moonstone badger guardian tied to Bracken's lore. It uses mine rings, weaving crystal volleys, a warning-marked slam, capped summons and moving burrow phases.
- Co-op keeps the surface and warrens as a single expedition. Mine state and burrowing visuals synchronize; the boss appears in its reachable crypt after the thirty patrol enemies are defeated.
- Spatial scenery collision, cached pathfinding and camera culling keep the larger world practical. All four arrivals, patrol starts, tunnel endpoints and the boss chamber are checked for access.

- Hollow Warlock keeps its imp summons and gains Cinder Fork: a visible flame orb that splits into two smaller shots. Shooting and summoning use separate timers; multiplayer hosts also enforce its two-minion cap.

Validation: Rendered surface, tunnels and boss chamber inspected. Solo/multiplayer summoner firing, splitting and minion caps checked. Godot import/compile; v40 tests for oldest-rune return, longer stun, actual solo door input, names, all patrol routes, tunnel travel, mine warning/damage, all six enemy styles, boss patterns and co-op snapshots. Existing v39, v36 and v38 checks also pass. Local engine checks do not replace a physical phone playtest.

Export the Web build in Godot and upload it to itch.io as usual. No Render changes are needed.
