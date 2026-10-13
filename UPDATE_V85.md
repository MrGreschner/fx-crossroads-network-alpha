# FX Crossroads v85 — Companions, counters and character movement

This complete editable project includes **all v84 work** and the new v85 additions. There are now **56 playable heroes**. Nothing has been deployed to itch.io or Render automatically.

## Movement and balance

- **Polarity:** floats above its ground position and gently bobs even at rest. Collision and attack origins stay on the ground.
- **Spindle:** gently alternates left/right while travelling, without increasing travel speed.
- **Aurel:** leaves alternating red footprints. They fade after 1.6 seconds, are cosmetic and have a fixed maximum count.
- **Snowdrift:** top speed reduced from 200 to 180. Accelerates, turns gradually and coasts briefly on release. Normal collision still applies; opening a menu clears stored movement.
- **Agent Smith:** replaces the display name The Agent.
- **Molten Pilgrim:** primary direct damage 54 → 32; secondary landing 32 → 22. Impact burn is 1 per second for 3 seconds. Ground lava deals 3 per second, with no overlapping-patch multiplication from the same owner. Long Migration mastery landing damage is now 14. The slow crawl and lob travel remain.

## Morrow Shepherd

A hooded keeper of forgotten spirits, with original four-pose art.

- **Gravespark:** a 21-damage, non-piercing spirit dart; 0.65-second cooldown.
- **Raise Remains:** aim at grave markers left by defeated ordinary enemies. Raise up to two melee echoes for 18 seconds. Each has 42 HP and deals 10 every 1.2 seconds. Markers expire after 25 seconds; raising consumes them. Bosses cannot be raised. The training yard supplies practice markers so this kit can be tried there.
- **Grave Chorus, level 5:** allows a third echo, with a ranged attack, and raises each echo’s health to 60. Raising again cannot exceed the cap or create multiple ranged echoes.
- **Life Lattice:** for 7 seconds, the hero and echoes share their actual remaining health. Damage to any linked body drains the pool. Red lines steal health from enemies crossing them, capped at 6 HP per second across the whole group. At expiry, 60% of remaining health is reserved for the hero, the rest for echoes, with maximum-health caps and overflow handling. Redistribution does not count as healing. Area attacks can damage multiple linked bodies, so clustering still has a cost. Cooldown: 22 seconds.
- **First mastery — Wide Vigil:** wider corpse selection, longer cooldown.
- **Final mastery — Last Procession:** replaces Life Lattice. Echoes rush an aimed point and burst for 24 damage each, briefly slowing nearby enemies, then disappear.

Echoes are independent allies, never added to the room’s enemy count. They cannot grant extra kill XP or keep an otherwise-cleared encounter locked. They can take melee, projectile and area damage in solo and multiplayer.

## Glimmer Mantis

An insect duelist built around a roster gap: a brief, deliberate parry window that earns offensive resources.

- **Scissor Feint:** alternating close cuts for 22 damage; 0.55-second cooldown.
- **Mirror Guard:** a 0.45-second window blocks one hit of at least 5 damage after reductions and earns one Poise. Maximum three; shown as three diamonds above the hero. Small damage-over-time ticks cannot farm charges. Cooldown: 4.5 seconds.
- **Second Wind, level 5:** a successful guard heals 8 HP, at most once every 6 seconds.
- **Glass Verdict:** three advancing diamond cuts along the aim line. An enemy is hit only once: 42 damage plus 10 per spent Poise, up to 72. Cooldown: 12 seconds.
- **First mastery — Long Scissors:** more reach and 24 damage, slower 0.75-second attacks.
- **Final mastery — Patient Execution:** replaces the travelling cuts with a clearly marked 0.8-second wind-up and wide close finisher: 88 + 12 per Poise, 18-second cooldown. Aim and origin lock when cast.

Both new heroes have titles, normal mastery requirements, crit milestones and two alternatives on different ability buttons. The student ability catalogue and both complete mastery catalogues are updated.

## Included from v84

- Nullweaver’s primary uses the clicked distance.
- Kite Corsair holds its grapple while secondary is held, then releases toward current aim.
- Tide Keeper and Spark Keeper work independently and combine friendly water/lightning effects. Their first mastery is earned by clearing their home realm together in co-op.
- Shuttlewick is an animated weaving shuttle with seam travel.
- Paradox Regent records, rewinds and replays attacks.
- Confluence Foundry is a structured medium–hard realm with two sluice wings, a locked heart bridge, optional healing condenser, unique enemies and the Divided Heart boss.

## Validation and limits

Passed: v85 solo and host-side co-op combat tests; v84 solo/co-op regression tests; North Gate and arena regression tests; all **22 room-service tests**. Native rendered previews checked Morrow’s links and Glimmer Mantis’s guard/cuts. Tests cover actual ability dispatch, corpse consumption, summon caps, health conservation, pool depletion, single-hit parries, snapshots and prior Foundry progression.

Headless test shutdown still reports existing resource-cleanup warnings; no script/runtime errors occurred during these checks. This is not a physical-phone or school-network soak test. The download is the editable Godot source project, not an already-exported itch.io Web ZIP or Windows executable.

## When ready to release

1. Extract this ZIP and open `FX_Crossroads/project.godot` in Godot. F5 runs the project.
2. Deploy the included `room_service` files to Render: **service version 19**. The URL, environment settings, root directory and start command are unchanged from the previous Node service setup.
3. Export fresh Web and Windows builds using the included presets/workflow. Upload the exported Web ZIP to itch.io; do not upload this editable source ZIP as the browser build.
4. Everyone in the same multiplayer room must use v85. The room service keeps incompatible versions apart.

No deployment was performed as part of this update.
