# v103 — Device diagnostics, smoother realms and deeper Descent

All 74 playable heroes remain available. Existing profiles gain a default Descent record without losing their other progress. This is editable source, not a compiled itch.io upload.

## Performance and diagnostics
- Gameplay/passive auras are suppressed in town, including Tova and Wick-o'-Wisp. Cosmetic movement traces remain visible.
- Options → **Run diagnostics / speed test** opens an on-screen report. Run its five-second check to see observed FPS, frame delays, selected cap, render resolution, draw calls, game memory, hardware/browser details where exposed, and multiplayer connection information. Nothing is automatically uploaded or downloaded.
- This is an observational frame test, not a maximum-capacity stress test or internet speed test. Solo AI is paused while the report is open; multiplayer continues. The selected FPS cap affects its result.
- Honeyglass's authored floor graphics are retained instead of rebuilt every frame. Floor polygons and nearby solid props are indexed for collision queries. Animation and collision geometry remain intact.
- Folded Coast's paper-island scenery and Moonveil's festival props are retained. NPC lookups used by combat are indexed once per frame.
- New enemies: **Crease Sentry** in Folded Coast fires paired weaving paper bolts; **Lunar Usher** in Moonveil marks a delayed slowing spotlight and releases a ring of petals.

## Ram's Descent
- After hero level 10, each level queues one choice: **+2.5% ability damage**, **+18 maximum health and 18 healing**, or **2 percentage points less cooldown**. Cooldown reductions cap at 20%; capped choices cannot waste a reward. Choices are run-specific and host-validated.
- Normal floors after floor 1 have a 55% chance of one floating **Vitality Geode**. Break it with an attack to recover up to 30 health. It gives no XP, kill, damage mastery or spell-healing credit and never blocks floor completion.
- Every fifth floor is a mini-boss encounter. Every tenth is a boss-only encounter. No ordinary enemies or summons join those encounters.
- Floor 30 introduces the **Sovereign of the Deep**: mobile steering, a telegraphed charge, radial crystal shots, falling crystals and a crossing fissure attack. This encounter repeats at floor 60 and beyond with increased health.
- Boss health scales with floor and party size. Descent navigation queries are staggered to reduce repeated work.
- The player card records deepest **cleared** floor, solo or co-op. Its badge grows at floors 5, 10, 20, 30 and 50. Teacher testing does not earn the record.

## Arena and lobby fixes
- Arena spawn/respawn locations are checked against obstacles using the hero's footprint, with nearby open-ground alternatives and player spacing.
- While a room is waiting, hosts can change mode, realm, seats, bots, AI difficulty, maps, team rule and spectator status without rehosting. Hero selection remains available. Settings that would exclude existing human members are rejected; no one is automatically kicked. Settings remain fixed during an active match.
- Removing bots removes their lobby/combat state. Changing spectator status frees/restores the host's fighter seat.

## Visual clarity and balancing
- Molten Pilgrim leaves a continuous red slime trace rather than alternating steps.
- Crossroads Teacher's primary shows only the forward melee fan, matching its damage area, rather than a full circle.
- Thorn Archer fires a small green arrow instead of the generic round projectile, in solo and multiplayer.
- Main-menu hero/enemy sets rotate every seven seconds (previously twelve).
- Wick-o'-Wisp: primary 18 damage, 1s recovery, burn 1.5/sec for 3s; Scary Face 150 reach, 0.85s stun, 9s recovery; Trick or Treat 16 treats, 4 damage per landing, 26s recovery. Its supportive passive is retained.

## Deployment
Room service and game use **protocol 28**. Read DEPLOY_V103.md. v102 rooms use protocol 27 and cannot mix with this build.

Local component timings show substantially less repeated Honeyglass work, but these are not school-browser FPS measurements. Browser GPU/driver failures can still occur; compare the new report across school PCs and test the exported build before class.
