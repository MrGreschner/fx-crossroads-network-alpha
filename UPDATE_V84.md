# v84 — Confluence Foundry

## Controls fixed

- **Nullweaver:** primary pins now use the clicked distance, clamped to attack range and intervening walls. A small ring previews the primary placement; the larger special guide remains separate.
- **Kite Corsair:** hold secondary to orbit the aimed anchor and accelerate. Release secondary to launch toward your **current aim**, not the orbit tangent. The maximum hold is four seconds. Mouse and touch button release use the same input state; remote releases are host-authoritative and send launch momentum back to the player. Walls still stop the swing.

## Four complete heroes — 54 total

| Hero | Play style | First technique | Final technique |
|---|---|---|---|
| Tide Keeper | Otter water engineer: water darts, sluice pools, a large rolling waterwheel. Water slows briefly; his passive shelters allies inside his fields. | Wider, weaker sluice pool | Three-dart Rain Harp replaces primary |
| Spark Keeper | Human conductor: lightning notes, relay fields and Thunder Score’s converging chords. His passive gives movement speed inside his own fields. | Longer, weaker relay | Double Overture replaces primary |
| Shuttlewick | Living wooden weaving shuttle: stitch a seam, then zip toward its endpoint, cutting crossed foes. A diamond loom controls an area. | Longer, weaker stitches | Heavy Loose Ends volley replaces special |
| Paradox Regent | Masked timekeeper: aim where a projectile splits sideways, rewind your last three seconds of movement, replay your last three primaries from recorded origins. | Longer, slower primary | The Still Hour control field replaces special |

All four have four original sprite poses, a mastery title, crit milestones, tuning support, two alternatives on different ability buttons and profile portraits. Titles and final techniques use normal progression.

### Water + lightning

Tide Keeper and Spark Keeper operate independently. Every water/lightning shot and damaging field can apply a three-second mark. A different friendly hero's opposite element consumes it for a 10-damage discharge within 85 pixels. Friendly overlapping water/lightning fields add one 5-damage pulse per water tick, regardless of how many relays overlap. There are no recursive reactions or cross-team combinations.

**Their first techniques unlock by clearing Confluence Foundry in co-op with both heroes selected.** Each player earns the unlock for their own selected pair hero. The profile export preserves it. Solo clears or ordinary grinding do not substitute; teacher mode still unlocks it for testing. The mastery card describes the challenge directly.

## New realm: Confluence Foundry

Medium–Hard, placed before Brasslock Borough. Start at the arrival dock, choose either Rainwork Hall or Copper Choir, and restore both sluices to open the east bridge. Rooms connect through narrow elevated walkways, with solid columns, animated waterworks, inspection grates, illuminated glass edges and brass pipework. An optional upper condenser offers a one-use 35-health reserve.

Three enemies introduce readable mechanics: Sluice Crabs telegraph close pressure splashes, Coil Singers charge narrow beam lanes while keeping distance, and Glass Menders restore nearby enemies and mark aimed glass blasts. The Divided Heart combines staggered water blasts, paired beam lanes and radial electrical shots, increasing attack frequency below half health. Defeat it, then interact at the glowing east exit.

Enemy health scales with party size. Co-op room checkpoints raise everyone to at least level 3 after the dock, level 4 after the first wing, and level 6 after both wings, so each teammate can use their full kit before the boss regardless of who lands kills. No checkpoint restores health. The realm remains playable with other heroes and solo.

## Student reference

ABILITY_CATALOG.md now includes the new styles, passives, partnership rules and custom co-op unlock. MASTERY_CATALOG.md and FINAL_MASTERY_CATALOG.md cover all 54 heroes from the actual definitions.

## Installation / deployment

This ZIP is the **editable Godot project**, not an exported itch.io Web build or Windows executable.

1. Extract to a fresh folder; open its project.godot and test with F5.
2. Update the existing Render service with the included room_service folder (**protocol 18 / package 18.0.0**). Keep the current service URL, environment variables and commands.
3. Export fresh Web/Windows builds. Have everyone in a room use v84; v83 and v84 rooms are separated.
4. Upload the exported Web ZIP to itch.io when ready. Nothing has been deployed automatically.

## Validation

Godot 4.5.1 import/parse validation, native rendering of the Foundry, exact pin targeting, held/released grapple direction, all four base kits and alternatives, chamber connectivity, locked/unlocked bridge, boss completion, co-op synergy/team isolation, shared checkpoints, snapshots and paired mastery results. Existing North Gate and arena regressions are also checked; room-service tests cover protocol isolation and capacity rules.

Headless scene tests may print pre-existing resource-cleanup warnings on exit. This does not replace a real two-device playtest: school-network latency, browser GPU stability, mobile feel and final difficulty balance need that last check before a school-wide release.
