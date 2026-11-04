# Crossroads V261 — Arena artwork update

Complete artwork release based on the authoritative V260 Editable. Godot 4.5.1. Build `V261-arena-art`. Report schema 3 and network protocol 11 remain unchanged. Nothing deployed.

## All ten maps

| Arena | Presentation update |
|---|---|
| Crossroads Coliseum | Detailed grass and soft path edges, woodland cover, wood/iron barricades, compass mosaic, matching supply depot. |
| Sinking Sands | Wind-rippled ochre sand and crumbling circular quicksand depressions; original 150px hazard rings remain visible. |
| Stormcoil Pit | Weathered slate/iron flooring and detailed twin-rotor drones, with restrained rotor motion and original overload warnings. |
| Wildbloom Glade | Moss, leaf litter, painted tree/rock cover and detailed six-petal fire-spitting blooms. |
| Clockwork Crucible | Weathered bronze channels and stone floor, recessed slowly turning gear details; original lightning lanes retain their clear warnings. |
| Shifting Labyrinth | Limestone chambers, textured masonry walls, stone and bronze gates; teal/open, amber/closing and red/locked cues retained. |
| Lanternfall | Dark moss floor, layered cliff islands and detailed torch pickups, under the existing fading fog. |
| Colour Clash | Neutral pale tournament slabs, detailed capture beacons, readable text plates, original eight ownership colours and progress rings. |
| Crown Chase | Slate/gold mosaic floor, compass plinth and detailed gold/turquoise crown. Original carrying, throwing and pickup animations retained. |
| Shatterfloor | Detailed engraved tiles on all three jade, twilight and amber decks. Cracking tiles have bright warm borders, original cracks and countdown bars; missing tiles, landings and falls remain clear. |

The arena selection cards use actual V261 in-game thumbnails and preserve image proportions. Spectator terrain also uses the new artwork. The existing V241 town arena facade remains intact; this release updates the playable maps and their selection artwork. Existing updated heroes and creature art are carried forward.

## Gameplay preservation

Every V260 source file is retained. All authored scenes and content JSON are byte-identical, including the Coliseum scene. All map sizes, geometry, collision radii, cover locations, gates, service/interaction anchors, spawn logic and routes remain unchanged. Non-drawing functions and state/constants in arena_world, arena_variants, arena_objectives, arena_shatterfloor and arcade are text-identical: 243 unchanged functions, with six drawing functions changed. Arena gallery rules, text, selection callbacks and permissions remain unchanged; its preview drawing is updated.

Hazard radius/damage/timing, drone targeting, flower shots, gate safety checks, ambushes, torch cooldowns, fog radius, crown speed burden/throws/scoring, territory scoring/paint throughput, Shatterfloor timers/falls/hops/shoves, AI, rewards, records and network snapshots are unchanged. No balance adjustment, record reset, database migration or live server action.

## Verification

- 1,984 focused native assertions and the same 1,984 browser WebGL2 assertions pass. Cached material/prop visibility, complete tiles, retained geometry/authority state, original sand bounds, maze/fog counts, supplies E interaction, terrain cache bounds and mode isolation are covered.
- Arena rules: 66 assertions; objective rules: 44; Shatterfloor rules: 48. These include gate occupancy/ambush safety, seeded fog terrain, reachable torches, fog limits, bots, eight-player FFA/teams, paint balance, crown passing/interception/burden, all three decks/rounds, fall replication and AI survival.
- Selection/spectator checks: 12 native and 12 browser assertions pass. All ten selection callbacks are exercised; native/browser selection views and Coliseum spectator overview are captured.
- North Gate regression: 63,504 assertions pass, covering the shared terrain/world rendering hooks and preserving V260 behavior.
- 24 focused native and 24 focused browser views cover all ten maps, active hazard/ownership states, carried/flying crown, minimum-light fog, torch/cliff views and all three collapsing decks. Two selection views plus a spectator view are captured per runtime. Production Web boot is checked separately.
- Tests use frozen/repositioned inspection states and automated rule scenarios. They are not a human full-match playthrough, real multi-device latency test or school Chromebook hardware benchmark. Arenas have no added day/night cycle; Lanternfall is checked at normal and minimum light. Native shutdown retains inherited ObjectDB/three-to-four-resource warnings; no current script/parse errors. Browser software-GL screenshot readback may issue GPU-stall diagnostics.

## Efficiency

New gameplay pages total 5,570,560 decoded RGBA bytes (5.31 MiB): one 768×768 material atlas, one 1024×768 prop atlas and a 128×128 deck tile. The menu thumbnail page adds 2,304,000 bytes (2.20 MiB); total maximum new pages 7,874,560 bytes (7.51 MiB), loaded lazily and cached. Existing painted trees, rocks, grass, paths and supplies are reused.

Static ground draws remain in the existing 512px chunk cache, capped at 48 retained chunks. Focused arena traversal peaked at 28. Stationary chunks retain their instances. Arena atlas subregions use retained tile quads to avoid disappearing when a subregion is repeated over a merged rectangle. Visible wall/cliff work is culled; actor/hazard counts and original paint meshes are retained. No new shader, particles, render target, live light, physics object or network message. Drones, gears and rings use small existing-style draw animations; no per-frame image creation.

## Packages / installation

Apply Server Update before Web. Preserve existing secrets/runtime settings, databases/user data and Web cross-origin isolation headers. This release has not been deployed.

Editable is a complete `tar.xz` archive: extract it and open `Crossroads_Realms_Beyond/project.godot` in Godot 4.5.1. XZ compression keeps the growing complete project downloadable without pruning prior source files or assets. Art Sources separately preserves both new full-resolution generation originals and production briefs; the complete runtime/editable crops are already in Editable. Previews includes native/browser captures, before/after boards and all-ten-map views. Integrity records exact sizes, hashes and package checks.

## Continuation

Use V261 Editable as the next authoritative base. `scripts/arena_art261.gd` owns cached texture regions, arena ground/cover/building art, hazards, gates, objective props and deck drawing. `multiplayer_ground.gd` selects that path only in Arena; `arcade.gd` selects arena cover/building art and spectator terrain. The four arena rule modules delegate their drawing and retain authority unchanged. Assets are in `assets/arena261`; QA and evidence under `qa`; preparation/build/verification/package tools under `tools/release261`.

Build tools expect baseline `project260/Crossroads_Realms_Beyond`, candidate `project261/Crossroads_Realms_Beyond`, baseline Web/Server `web260`/`server260`, and outputs in `out261`. Generation originals are in the separate Art Sources archive. Integration and QA-extension scripts record the production steps; do not rerun them over the finished source. Unique frozen QA packs must never be overwritten while running. Old arena tests remain intact; current wrappers update the stale seven-map expectation to ten and direct result writes to writable `user://` paths. QA is included in Editable and excluded from production Web PCK.
