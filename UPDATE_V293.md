# V293 — Unique Cave Descent guardians

The eleven major Cave Descent bosses now use individual arena hazards and movement cycles. Their former shared major-boss strip/cross/circle schedule and themed copies of the same expanding wave are disabled. The ten mini-boss routines remain, as do the existing major-boss minion intermissions at depths20/40/60/80/100.

- Wick-Eater: curved burning wick, hungry breath and close pursuit.
- Widow: destructible web anchors, attached slowing strands, plucked-string strikes.
- Excavator: real invulnerable underground travel, trench slowing, warned breaches; rock collisions stop its charge.
- Oracle: stable islands, changing currents, reflected tides/pulses, surge and Ward.
- Tribunal: sequential claw sectors, destructible cover, cover-breaking quarry shots and charges.
- Hundredth Mouth: three actual head targets, independent bite/venom/drain attacks, visible22/20/18-second regrowth timers, poison rivers. Heads use regions of the unchanged original sprite. Each living head grants12% body damage reduction, encouraging head management while keeping the body damageable.
- Facet Leviathan: destructible reflectors interrupt linked multi-segment beam paths, crystal growth and shard attacks.
- Bell Below: sequenced sound sectors blocked by stone, delayed echo, interruptible healing bell, expanding projectile-clearing pulse. Both teams' cave bolts, combat projectiles and missiles are cleared; swept interception prevents fast shots crossing it between updates.
- Cinder Regent: airborne repositioning, warned scorched passage, furnace drafts that turn wheels, returning shots and3–4 hatchlings.
- King: royal wall formations and breakable seal, advancing execution charge, two oath guards reducing incoming damage by35%, and delayed Crown Sentence per living hero (central impact followed by two outer rings). Five original minion intermissions retained.
- Unquenchable: warned lava channels with bridge gaps, usable/attackable cooling vents,45% incoming-damage armoured shell, exposed-heart windows. Two additional stages at65%/30% HP with minion intermissions: Caldera Fracture adds fissures and summons; Heart Unbound adds staggered lava arcs and denser channel patterns.

Openings generally mean recovery time with15% bonus damage, not compulsory immunity. The Excavator is untargetable underground; Oracle Ward retains60% reduction. Vents expose the Unquenchable for9seconds. Interactive props award no enemy-kill currency/XP; spawned brood has no currency bounty. All boss base statistics and hero artwork remain unchanged; challenge comes from encounter mechanics. No automatic record reset beyond the already prepared V292 Cave migration. No deployment.

Verification uses Godot4.6.3 native fixtures, including real combat entrypoints, one/four-hero host simulations, JSON/enemy packet reconstruction, collisions, head deaths/regrowth, projectile interception, minion phase thresholds/return and actual Canvas draw callbacks. These are not human combat playthroughs or real network sessions. Target4.5.1 remains unchanged; fresh target exports, browser/co-op sessions and classroom-device performance/play balance require playtesting. Original ObjectDB/three-resource shutdown warnings persist.

Install the matching Web and Server candidates together. The packages are verified incremental updates of saved V292, not fresh4.5.1 engine exports. The cumulative source delta restores over all four V278 Editable parts; V292 plus those parts is rollback. See the final handoff and integrity report for exact hashes and test results.
