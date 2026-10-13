# Version 23 — distinct heroes and the final challenge

All version 22 content remains.

## Hero changes
- Reed’s Silverfall Surge: expanding waterfall, 48 damage, 90 knockback, 3-second slow. River Skipper passive gives each secondary stone one additional bounce for 65% damage within 180 distance.
- Mara’s Open Wound passive: primary hits bleed for 2 damage/sec for 4 seconds, refreshing without stacking. Bleed is red; burn is orange.
- Stormscribe’s Thunderfall: a travelling crackling orb and lightning burst; damage occurs on landing.
- Polarity’s passive allows three anchors. Live Wire connects all three; intersecting links do not multiply tick damage.
- Star Navigator’s Seeking Orb adds 8 splash damage within 75 distance around the direct victim. Twin Stars passive launches two homing orbs.
- Sunpetal fires four consecutive straight seeds, 0.1 seconds apart. Its low damage and divided equipment bonus remain.
- Frostguard’s secondary cooldown is now 2.2 seconds. Cold Reprisal passive slows melee attackers for 3 seconds; ranged/DOT hits do not trigger it.
- Spindle is hero 20: alternating curving darts, three orbital shards and a three-second pulling/slowing vortex. Each shard hits an enemy once; vortex damage is capped at six ticks. Its passive extends orbital shards by one second.

All revised passives unlock at level 5. The student base ability sheet, `ABILITY_CATALOG.md`, includes new styles, fields, examples, status colors and passive behavior.

## World fixes and challenge changes
- Six Ram Descent rocks now have art aligned to their collision instead of invisible barriers.
- Shattered Oath is 14,000 × 8,120 (40% larger per axis). Its trials have 18 enemies each and substantially tougher guardians. Sixteen enemies defend the portal hub.
- Every Oath guardian has a ranged projectile fan in addition to its previous attacks. Traps deal more damage.
- The Usurper moves continually, fires fans and uses a faster, stronger Soul Tax: 0.65-second warning, 26 damage, steals 36 solo XP or 24 multiplayer XP. Initial health is 1,300; the three fragments and nine later fragments are also stronger. Multiplayer health still scales with party size.
- Victory draws a glowing green exit seal near the final arena entrance. Interact there to finish; solo and co-op reachability and completion are checked. Stolen XP is restored after defeating all Usurper fragments.

## Validation and upload
Godot headless checks cover the new hero mechanics and passive unlocks, obstacle art/collision, all expanded portals and placements, each guardian’s ranged attack, thief mobility/Soul Tax, the 1→3→9 split and reachable solo/co-op completion. Older checks were updated where intended attack behavior changed. Physical mobile and real network playtesting remains needed.

Open project.godot and export a fresh Web build for itch.io. No Render service update is needed. This ZIP is the editable project, not the exported browser build.
