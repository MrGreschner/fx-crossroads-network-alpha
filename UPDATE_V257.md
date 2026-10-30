# Crossroads V257 — Sunfield Expanse

Completed 30 October 2026 from the authoritative complete V256. Artwork, implementation and local verification are finished. Nothing has been deployed and no live player records have been modified.

## The new course

Sunfield is now a 10,800 × 6,800 pastoral adventure with seven distinct areas: Ciderlight Orchard, Whispergrain Rise, the Sunwell Terraces, Sails of the Expanse, Amber Gorge Gardens, the Solstice Crown and optional Pollinator Hollow. Seven broad crossings connect raised sandstone landforms, creek cuts, stairs and a long diagonal skybridge. The Hollow forms an optional exploration loop rather than a dead end. Fourteen new painted sources supply apple trees, sunflower clusters, wheat, layered rock, a sun-carved arch, the Sunwell, a harvest wagon, the windmill and its moving sails, plus five small terrain materials. Soft coloured edges, matte shading and readable painted clusters follow the V207/V208 direction.

The map contains 22 walkable floor shapes and 543 prop markers, including four invisible arch-foot supports. Grass and paths have restrained warm variation; path edges feather into the meadow. Two small cascades are anchored to the bridge lips. Moving current strokes, seed motes, gentle crop sway and the turning windmill use bounded native drawing. Tree crowns and sails fade near players. Raised terrain is a 2D visual treatment: ramps/crossings remain ordinary walkable floor with cliff-edge padding, not a new jump or elevation mechanic.

The course retains its existing 20 defender types/stats, the 980-HP Sun Sentinel, two ability checkpoints (minimum levels 3 and 5), three discovery IDs/rewards, merchant and return gate. Locations move with the new layout. The ordinary clear-defenders → awaken Sentinel → defeat/extract sequence, rewards and unlocks remain intact. No hero/boss redesign or combat rebalance is included. Existing sunbeam warnings, active sunbeams and attack telegraphs remain visible through the new drawing path; discovery icons are retained with nearby readable interaction panels. Other realms and all previous completed work remain included.

## New-course records

This is a materially different course. The update resets Sunfield speed records only: combined, solo and co-op, all-time and weekly, matching hero provenance, local personal bests and stale queued Sunfield time claims. The new client tags Sunfield route state revision 257. New times survive subsequent loads and server restarts; old clients cannot silently repopulate the old timing boards.

Currencies, inventories, unlocks, clear/mastery progress, lifetime streaks, fish/gardening data, Descent records and other realm times are preserved. The client migration runs once on profile use/load. Cloud profile GET and save routes migrate older profiles selectively. The service initialization migration runs in a transaction with a locked revision row, backs up old timing rows and associated timing exclusions into dedicated course archive tables, removes them from active boards, then records revision 257. Snapshot filtering also hides unversioned Sunfield timing rows. Historical backups remain available for recovery; active speedboards start fresh.

This migration has **not** run on the live server. It runs when the matching Server Update is installed. Back up the database/server first. Apply Server Update before Web and use the matching version together.

## Verification

57,180 passing engine assertions: Sunfield 4,972; Firstbell 4,388; Honeyglass 3,212; Grove/Quarry 171; aquatic 35,637; Descent 4,350; marina/UI 4,450. Sunfield checks actual patrol count, 51 reachable course targets in solo/co-op, route-cell standability, solid props, cached navigation for both stages, checkpoints, discoveries, guardian health/spawn/defeat, completion, texture reuse, terrain-cache bounds/reuse, canopy fade, other-realm isolation, re-entry, overcharge event anchors, rare Conclave placement, selective local record migration and dedicated-server compilation. Independent Shapely analysis also reaches all 51 targets on a 30px grid with 20px clearance.

42 additional server assertions use PGlite's PostgreSQL-compatible engine, exercising actual SQL archives/deletion, injected transaction failure and rollback, idempotent restart with a new PB, preservation of unrelated records/exclusions, stale/new reports, snapshot filtering, selective immutable profile migration and encrypted account GET/POST save routes. These are isolated fixtures; no live backend test occurred.

Seventeen native and seventeen WebGL2 game previews cover the orchard, bridges, stairs, terrace, mill, gorge, crown, Hollow, low light, boss warning and active sunbeam, plus co-op views. The production Web build opens to its menu. Low light is a synthetic visibility stress tint; no new day/night system was added. Fixtures freeze time, reposition players and remove patrols for scenery; boss images use real spawning/beam methods. The six-second windmill clip uses 48 real renderer frames at eight frames/sec, with normal animation time. The overview uses actual terrain/prop resources at authoring scale and is not an in-game map feature.

19,103 existing Editable files remain byte-for-byte unchanged; every original file is present. Exactly 31 changed/new runtime resources match across Editable, Server Update and Web PCK. All other Web resources remain byte-identical to V256, except the versioned project settings binary. ZIP CRCs, duplicate paths and SHA-256 integrity receipts are checked.

## Efficiency and practical limits

One 1024×1024 prop atlas, one 512×512 rotor and five 128×128 material tiles add 5,570,560 uncompressed RGBA bytes (about 5.31 MiB), excluding driver/base-game overhead. Textures and atlas frames are shared/lazy-cached. Props use spatial bins and camera culling. Terrain is pre-baked into 173 source chunks; the normal-view retained cache reached and stayed at 48 or fewer chunks during the full-map camera sweep. Stationary frames reuse retained nodes. There are no per-plant nodes, new light/particle nodes, shader passes or per-frame terrain rasterization. At most 12 seed motes and bounded current/cascade strokes are drawn. Navigation uses revision-matched baked grids on solo/co-op authority.

`qa/evidence257/render_budget.json` includes observed native draw counts and texture memory. This was software rendering, not a school-device benchmark. Actual multi-device latency and live database deployment were not tested. Native fixtures retain the inherited ObjectDB/three-resource shutdown warnings; unavailable external-service fetches can appear during isolated browser startup. Final verification has no script/parse/page/WebGL errors.

## Packages and continuation

- Web: deploy its contents using the existing Web hosting setup and isolation headers, after the matching server update.
- Server Update: stop/back up the server, overlay the update while preserving secrets, environment/runtime configuration, databases and user files; import with Godot 4.5.1 as needed; restart normally. Confirm the service is ready so the migration has committed before accepting new timing uploads. No deployment was performed here.
- Editable: complete Godot 4.5.1 source project. Let the editor finish import. Campaign polygons/props remain editable in `content/campaigns/sunfield_paths.json`; the scene keeps the service/spawn marker nodes. Regenerate terrain/nav if geometry changes.
- Previews: actual native/browser images, compact montage, course overview and normal-speed windmill MP4.
- Art Sources: all fourteen full-resolution generated originals, exact prompts, source hashes and production brief. Runtime files are normalized technical derivatives.

Use this completed V257 release as the next base, not the earlier Working Checkpoint. New runtime art is under `assets/sunfield257`. `sunfield_art257.gd` owns prop/material caching and presentation; `sunfield_ground257.gd` retains terrain; `immersive_worlds.gd` scopes it to Sunfield. `sunfield_records257.gd` and `network_service/sunfield-course.mjs` own record revision 257. Tests and evidence are under `qa`; release tools are under `tools/release257`. Build tools expect complete V256 archives under base256, extracted web256/server256, and current source under project257/Crossroads_Realms_Beyond; art preparation can use the packaged Sources originals as fallback when original generator paths are unavailable. Never re-run the patch-style integration script against an already integrated tree; it is historical preparation tooling. For later layout edits, run layout257, rebuild the fixture, bake v257_navigation, update both Sunfield navigation stage files, rebuild and reverify before packaging.
