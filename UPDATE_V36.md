# Version 36 — distinct kits and hero 25

Bracken’s special is now Foxfire Escape: teleport up to 280 units along aim, stopping before obstacles, and leave a visible timed bomb at the original spot. It explodes after one second for 62 damage within radius 115. Cooldown 15 seconds.

Elara’s secondary is Prism Unfurl: three shards spiral outward from the fixed casting location for two seconds, reaching 250 units. Each shard hits each target once for 14 damage and stops at walls. Far Refraction replaces her orbit-duration passive with 60 extra units of spiral reach. Long blonde sprite poses are retained.

Aurel’s primary is Starfire Breath: a narrow 24-degree, 170-unit stream with four 4-damage ticks over 0.4 seconds. Hits refresh a 1-damage/sec burn for three seconds. It works from level one in solo and multiplayer. His wingbeat, meteor shower and passive remain.

Rune Duelist is hero 25, a human swordsman with original sprite poses. Inscribed Cut leaves runes and adds damage every third cut; Runestep returns to a reachable rune while damaging enemies along the route; Sigil Court connects nearby runes into a temporary triangular damage field. Lingering Script extends mark lifetime. These are shared new base attack styles, documented for students, with owner-specific synchronized state and collision-aware teleporting.

Checks pass for teleport distance, wall stopping, bomb placement/fuse/damage, spiral expansion/passive/damage and one-hit-per-shard, level-one breath damage and burn, three-cut combo, rune return and field ticks, 25-hero registry/network state, plus host fire breath and blink. Previous Aurel meteor and Backbeat/Moonveil checks pass. Browser/mobile playtesting remains after a fresh export. Includes all version 35 and earlier content; no Render changes required.
