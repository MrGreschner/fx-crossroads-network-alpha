# North Gate: Three Roads

The town gate is the shared objective. Three long, curved lanes meet at its fortified courtyard:

- **Bellwood Road** runs north through woods and across the stream bridge.
- **Old Mill Road** runs west, with a woodland trail to a pond and healing spring.
- **Emberwatch Road** runs east, with a ruin clearing and another recovery spring.

The minimap shows the actual curved roads, cyan outposts, green soldiers, purple rival hero and gold checkpoint boss. Water can be crossed at the bridge. Buildings have solid footprints, while their doors can be approached to interact.

## Allied soldiers and rewards

Every 20 seconds each lane receives **two base melee guards and one outpost soldier**. Guard-count upgrades add base guards; archery and sanctum upgrades add their respective troops. Living-soldier caps prevent endless stacking. Soldiers march outwards, fight nearby enemies, separate from each other and retire after reaching the far end or exceeding their lifetime. Outpost and base troops share upgrades.

A lane-guard kill awards **20% of the normal gold bounty to every player in the match**, including a downed player. Fractions accumulate: five regular guard kills yield two gold per player, rather than rounding each kill up or losing fractions. Small shared XP rewards accumulate at the same rate, helping support players progress. Guard damage and kills are not reported as a player's personal damage/kills. A player's summoned minion still credits its owner normally.

## Waves and party size

Enemy types progress from simple melee enemies and archers to faster attackers, durable enemies and harder ranged patterns. Waves arrive roughly every 20–25 seconds; a crowded battlefield delays the next batch instead of spawning unlimited enemies. Early fronts start closer to the gate, then extend farther down the full lanes.

| Players | Enemy-count multiplier | Enemy-health multiplier | Enemy-damage multiplier | Upgrade-price multiplier |
| --- | --- | --- | --- | --- |
| 1 | 1.00 | 1.00 | 0.82 | 0.80 |
| 2 | 1.50 | 1.18 | 0.93 | 0.90 |
| 3 | 2.05 | 1.40 | 1.00 | 1.00 |
| 4 | 2.75 | 1.65 | 1.08 | 1.05 |

The starting party size fixes scaling for that match. Three players suit one lane each. Solo gets lighter damage, fewer opponents and cheaper shared upgrades; four players face substantially more pressure. These are initial balance targets, not proof of equal win rates. Student playtesting should compare time-to-wave-30, deaths, gate health and upgrade levels.

## Sable Voss — returning rival

Sable is an enemy raven duelist, not a selectable player hero.

- **Primary: Talon Bolts.** Ranged pressure; a second angled bolt joins the attack at level 4.
- **Secondary: Shadow Snare.** Level 3 unlocks a delayed marked blast that damages and slows heroes caught inside.
- **Special: Crossfire Decree.** Level 6 unlocks three marked launch points that release explosive shots after charging.
- **Movement:** Keeps distance, strafes, leads shots against moving targets, looks for exposed targets, changes lane when unopposed, retreats at low health and uses a five-second dodge cooldown against nearby threats or incoming projectiles.
- **Progression:** Earns one XP per guard kill and six per player knockout. Levels increase health and damage and unlock abilities, up to level 12.
- **Respawn:** Returns after 14 seconds plus 0.6 seconds per level, retaining earned match levels. A new match resets progression. The recurring rival does not prevent a wave from being cleared.

## Wave 30 — The Tollbreaker

A large armoured bell siege construct attacks with three rotating patterns:

1. Delayed triple Bellfall blasts.
2. A spread of explosive siege shots.
3. A charged shockwave followed by radial projectiles.

Further waves pause until the boss has actually been defeated **and** all remaining attackers from wave 30 and earlier are gone. The boss cannot disappear into the gate and accidentally grant the unlock: it attacks the gate repeatedly if it reaches it. Clearing the checkpoint earns the existing town bastion/wall upgrade and a victory notice. Endless defence can continue afterwards.

## Student authoring

`content/modes/north_gate.json` holds pacing, actor caps, reward shares, respawn timing and party multipliers. The map scene holds road polygons, collision trees, upgrade buildings and springs. `north_gate.gd` owns lane coordinates, AI, warnings, checkpoint rules and their host/guest display state. Keep route coordinates and road art aligned when changing the map. New bot attacks must include warnings, damage, cooldowns, death/respawn handling and snapshots.
