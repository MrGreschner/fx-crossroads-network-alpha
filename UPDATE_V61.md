# v61 — Kage Moonstep, stronger saw form and chain utility

Includes all v60 changes. 41 free heroes; no new realm or Render server changes.

## Bolt Ironcore
Iron Tempest grants 30% damage reduction for the whole saw form, including transformation windup. Reduction combines with other defenses without granting immunity.
Each enemy defeat credited to Bolt while the form is active adds one second to its remaining duration. This includes his lingering missiles or damage-over-time kills, as well as contact and stomp kills. Co-op uses the actual killer; PvP player defeats also count. Training dummy resets, ordinary hits and intercepted revivals do not count. The timer and a +1s flash show extensions. Existing slow movement, no-dodge restriction and Shock Stomp remain.

## Rook Ironhand
Chain Sweep's chain now slows enemies it crosses by 30% for 1.5 seconds. This does not apply flail damage; the tip still deals damage once per target per swing. Walls block the slow.
Grapnel Rush deals its existing 18 damage plus a 2-HP drain and restores up to 2 HP per enemy hit, once per rush. It cannot heal from an invulnerable target or exceed maximum health. Stun and Follow Through remain.

## Hero 41: Kage Moonstep
A masked ninja from Moonveil, free and appended to the hero list. Health 100; movement speed 260.

| Ability | Behavior |
| --- | --- |
| Twin Fang | Two katana cuts, 0.14 seconds apart, 12 damage per cut within 95 reach. Cooldown 0.8s. |
| Windwheel | A spinning shuriken travels outward for 24 damage then curves back for 16. Once per enemy on each leg; walls stop it. Cooldown 7s. |
| Eightfold Eclipse | A marked moon-circle warns for 0.3s; eight stars spiral inward over 1.2s. Up to three 12-damage star hits per enemy, then an 18-damage center burst within 90 radius. Cooldown 18s. |
| Moon Thread | At passive level 5, returning Windwheel hits mark enemies for 3s. The next Twin Fang hit consumes the mark for 8 bonus damage. |

All attacks use visible swept paths, respect walls and exclude allies. Special stars disappear on wall contact; the cast ends if the ninja dies. Multiplayer snapshots carry timed cuts, flying stars, spiral positions and marks. Original matching pixel art includes idle, walking and attack poses.

## Student materials and validation
ABILITY_CATALOG.md and STUDENT_GUIDE.md describe the three new styles, return-leg marks, kill-time extension and chain contact slow.
Tests cover real kill credit, timer extension, reduction, chain-only slow, distinct-target health draining, protected targets, timed cuts, two-leg hit limits, passive consumption, spiral damage caps, multiplayer state and PvP/friendly targeting. Robot, Rook, mirror survival, elemental lanterns, school and multiplayer regressions passed. Character Hall and combat visuals were inspected in Godot.

Export a fresh Web build for itch.io. No Render changes needed.
