# v62 — The Agent

Includes all v61 content. Hero 42 is free and appended to the Character Hall list. No additional realm or Render changes.

## The Agent
A Crossroads operative with sunglasses, a coat and a red-light weapon. Health 110; movement speed 240. Original pixel artwork includes idle, walking and attack poses.

| Ability | Behavior |
| --- | --- |
| Scatterlight | Seven thin red laser rays in a 36-degree cone, 6 damage per ray (maximum 42), 420 reach, 1-second cooldown. Each ray stops at the first foe or wall. |
| Corner Lens | Deploy a floating relay up to 260 ahead. It arrives in 0.35 seconds and remains active for 5 seconds. Shotgun rays touching its 32-radius lens redirect toward the nearest visible enemy within 360, at 80% damage. Reflected rays still stop at walls and their first target. Cooldown 6 seconds. |
| Ambush | Select an enemy within 650. Three circles at -60, 0 and +60 degrees on its far side flash twice, then projected agents appear after 0.6 seconds. They charge for 1 second and each fire one powerful beam for 32 damage. These 1000-reach beams pierce enemies and walls. Cooldown 24 seconds. |
| Crossfire Protocol | Passive at level 5: lens-bent shots mark enemies for 3 seconds. Ambush beams deal 5 extra damage per beam to marked enemies. |

Ambush circles are 180 units from the selected enemy. Their positions are fixed when the attack begins; the beams aim at the enemy's current position when firing. If that enemy dies first, the beams aim at its last recorded position. The projected agents are visual operatives, not independently damageable player bodies.

## Targeting and balance
Mouse targeting chooses the nearby enemy under the cursor; directional aim assist supports touch controls. A red reticle shows the intended target after special unlock. With no valid enemy, Ambush does not spend cooldown.
Shotgun damage and bonuses are divided across seven rays. All rays are planned before applying damage, so killing a front enemy cannot make the rest of that same burst pass through it.
Corner Lens creates new angles rather than granting wall penetration. Only the special pierces obstacles. All attacks exclude the caster and allies; PvP opponents can be hit. The host resolves damage and guests render synchronized rays, relays and charging agents.

## Validation and student notes
Tests cover first-hit ray blocking, simultaneous burst occlusion, range/spread, lens redirection, marks, rear 120-degree placement, two-flash warning, full charge delay, single-fire damage, wall piercing, invalid targeting, friendly/PvP targeting and multiplayer snapshots/authority. Ninja, robot/Rook upgrades, elemental lanterns, schools and multiplayer regression checks passed. Character Hall, shotgun, relay and special graphics were inspected in Godot.
ABILITY_CATALOG.md and STUDENT_GUIDE.md include the new ray and delayed-squad styles.

Export a fresh Web build for itch.io. No Render changes required.
