# Crossroads: Realms Beyond — V198.39

Build: `V198.39-town-rendering` · Godot 4.5.1 · Protocol 11.

This is a cumulative update on V198.38. It retains the Academy/Studio/assessment work, Descent overhaul, fish, Warforge, new realm enemies and community-record improvements already delivered. This update focuses on town rendering; nothing has been deployed.

## What changed

- **Shared terrain texture:** grass, paths, flowers and five other existing basic terrain tiles now share one small padded atlas. Existing 512-pixel retained ground chunks can draw those tiles without repeatedly switching textures. Each original tile's pixels are unchanged. Other/custom terrain textures retain the existing fallback.
- **Fixed town details cached as artwork:** bridge/deck planks, mooring ropes, marina fittings, cottage day/night facades, Studio and Academy masonry, rail sleepers, street beds, the pond structure and lookout no longer rebuild hundreds of primitive draw commands every frame. Fifteen layers use 57 trimmed tiles across two atlas pages. Only tiles intersecting the current view are drawn.
- **Living details remain animated:** town residents and guards, traders and their daily stock, gardener, bobbing boats, old marina tree, smoke, water, fish, magical portal, flags, weather and lights still run. Boat bobbing now uses the boat's world position, keeping its phase stable while the camera moves. Interaction and access highlights remain live.
- **Lighting field retained:** the night-light mesh stores spatial lamp falloff separately from ambient colour. Time and weather tint it without rebuilding the vertex colours twice per second. Camera grid crossings, viewport changes and the changing campfire still invalidate the field. The wider light-source margin prevents lights entering the view from being omitted; off-screen glow accents are culled.
- **Less invisible drawing:** off-screen sprites, fireflies, mushroom accents, arena effects and acorn glows are skipped. Marina-reserved trees are filtered once before the scenery collision index is built, instead of being removed repeatedly during rendering.
- Cleared two old cargo obstructions from the marina guard route and opened the cliff collision along the existing Deepwell Exchange doorstep/street spur.
- No camera zoom option has been reintroduced. Existing draw/lighting/frame diagnostics and hardware information continue to feed performance reports; no database migration is needed.

## Local before/after test

Same 1280 × 720 native scene, Godot Compatibility renderer, Mesa llvmpipe software OpenGL. Each fixed view has 40 warm-up frames followed by 75 samples. The following are nighttime medians; the JSON also includes daytime and walking samples.

| View | V198.38 draw calls | V198.39 draw calls | Reduction | Local frame time (ms) |
| --- | ---: | ---: | ---: | ---: |
| Central square | 803 | 495 | 38.4% | 26.40 → 22.68 |
| Marina | 950 | 229 | 75.9% | 31.14 → 18.42 |
| Academy / Studio | 655 | 374 | 42.9% | 26.32 → 18.06 |
| East river | 553 | 223 | 59.7% | 23.70 → 24.40 |

Walking through the square reduced median draw calls by 33.7%; walking along the marina reduced them by 76.0%. These are reductions in drawing work, not guaranteed FPS gains. The host uses software rendering; it is not a school Intel/AMD integrated-graphics machine. Classroom device testing remains necessary.

The new scenery pages use 17.0 MiB decoded GPU texture space plus a tiny terrain atlas. Their compressed PNGs add roughly 200 KiB. They are ordinary cached textures, with no additional live render targets or per-frame texture uploads.

## Visuals, state and compatibility

The atlas regions reproduce all 57 native bake images byte-for-byte; all eight terrain tiles reproduce their original PNG pixels. Fixed artwork keeps its authored size and world location. Dynamic effects, weather and the HUD remain separate. Pixel-level lighting checks compare the rendered field against exhaustive lamp calculations at every vertex for day, night, dawn, rain and mist. Existing clipping and blend rounding can differ slightly at raster edges; no town redesign is intended.

Accounts, saves, currency, schools, assignments, keys and the production database were not changed. Existing realm and multiplayer rules are retained. The editable project includes the source drawing functions, bake/pack tools, regression checks and the benchmark script so students can continue editing artwork. When fixed town art changes, rebuild its atlas using `tools/bake_town39.gd` followed by `tools/pack_town39.py`; `tools/pack_terrain39.py` rebuilds the basic terrain atlas.

## Deploy manually

1. Deploy `Crossroads_v198_39_Server_Update.zip` to the existing Render service first. Keep the existing database and environment variables/keys.
2. Confirm `/health` identifies `V198.39-town-rendering` and verify the existing live account/database services.
3. Upload `Crossroads_v198_39_Web.zip` to itch.io and reload open clients.
4. On a computer without a dedicated graphics card, check walking through the square, marina, Academy/Studio and river in daylight and darkness. Capture a fresh performance report after at least a minute of movement. Local automated checks do not replace this device check.

Use these cumulative ZIPs instead of V198.38. No production deployment or account/database reset was performed.
