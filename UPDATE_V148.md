# v148 — Realm Builder production workspace

The Realm Builder now shares a native terrain/prop renderer with its standalone Godot playtest. Grass, roads, river water, stone, sand and ice use game artwork. Connected road/river edges, animated water, prop shadows and foreground occlusion improve readability. Starter objects use real game assets; eight additional detailed props replace mismatched crate/barrel/cart/tent/sign/bookshelf/well/archway placeholders. Your own uploaded/drawn artwork is preserved.

## Build a full realm
- Maps: 8–256 tiles per side; each tile is 40 world pixels. Maximum world size is 10,240 × 10,240 pixels.
- Up to 1,000 placements, 64 enemies, 32 object types and 12 enemy types. Portable project size remains 2 MB; embedded art uses that budget too.
- Wheel zooms around the cursor. Right/middle drag pans. Click the minimap to travel; Fit map and Go to spawn are available. On touch use Touch pan, then choose a terrain/object tool again to paint.
- Terrain brushes: 1, 3, 5 or 9 tiles. Continuous strokes prevent gaps. Undo/redo keeps twelve terrain/placement/spawn/exit revisions. Vision and environment edits are not included in paint undo.
- Terrain settings independently control movement/projectile blocking, movement speed and damage per second. Sand slows by default; lava is blocked by default. Make lava walkable to use it as a damaging route. A visual bridge does not override blocked water: paint a walkable crossing beneath it.
- Weather: clear, rain, snow, fireflies or ash; adjustable intensity. Lighting: day, dusk, night or moonlight. These atmospheric presets are visual; terrain controls gameplay hazards.
- Choose a reach-exit goal or require clearing enemies first. Route checks reject blocked starts/exits, disconnected routes and enemies on blocked cells.
- The enemy palette includes game sprites and saved custom enemies. Official enemies are adapted to the bounded Enemy Lab runtime, not a byte-for-byte copy of every official boss script. Use Enemy Lab for custom behaviours and attacks.
- Choose the current Workshop hero or a saved custom hero for testing.

## Finalize & Play
Finalize validates and saves the local project, then opens a full-window camera-following realm, with the same terrain/props/collision data. WASD and mouse attack controls work; hold/release custom attacks are supported. Reach the gold portal to finish. Restart resets the entire test. End test or Escape returns to editing and records the result. This is an isolated creator playtest: it does not award account XP, mastery or trophies, or publish the realm to official multiplayer.

Chasing enemies use grid navigation to route around blocking terrain and props. Distant enemies sleep outside the nearby play area. Terrain renders in reusable visible chunks, with at most sixteen 640-pixel terrain textures cached. The editor uses an overview at distant zoom rather than drawing every tile of a huge map. Data-only JSON projects and the existing profile ZIP remain supported; imports never execute student scripts.

Official hero moves, official realm gameplay, town layouts and education outcomes were not changed by this update.
