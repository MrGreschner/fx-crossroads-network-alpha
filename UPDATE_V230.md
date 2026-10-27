# Crossroads V230 — clear intro arch and refreshed town cast

## Intro

Before activation, the stone arch now has a transparent centre: the same scenery is visible through it. This is corrected both in the native Godot film shader and the browser canvas film, including day, night and reduced-motion playback. Portal energy fades in with the existing activation beat. Camera, actor placement, scene artwork and timing are preserved.

## Town cast

36 existing identities refreshed / 108 poses:
- All 21 named wandering residents: ram, rabbit and human citizens, retaining their names, species and main tunic colours.
- Seven storefront/guide identities: supply keeper, Moss, Tessa, Scout Alden, Rowan, carpenter and wayfinder guide.
- Ramguard foot soldier and archer, consistently used at town posts, patrols, barracks and marina.
- Brin and Lio, the marina's day and night bait traders.
- Ox farmer, fishing shop bear keeper, squirrel postal worker and exchange ram worker.

Soft coloured contours, coarse pixel clusters, matte material shading and neutral front-facing poses match the updated heroes. Idle plus two alternating walk frames; poses are registered to stable body anchors. Existing visible world heights are retained, including the larger ox and long-eared rabbit healer. Stationary shopkeepers and working residents use idle artwork rather than continuous walking. Activity props and existing interaction targets remain.

One cached 240×2880 texture atlas holds every pose. No per-frame image processing, resizing or new render targets. Unused old guard/farmer texture loads removed. This is a visual update, not a measured real-device FPS claim.

All town schedules, errands, patrol routes, weekly events, shops, trading, farming, fishing and gameplay interactions remain. No combat balance, hero art, realm maps, progression, records, database data or backend configuration changes. V229 enemy alignment and movement-gated idle fixes remain included.

## Verification

- 981 focused Godot checks: all 108 poses, cached loading, transparent/unclipped frames, distinct steps, world sizes, all resident identity mappings, ten live integration paths and inactive/active portal rules.
- 4,574 shared hero/stat/authority/Cave checks.
- 44 browser film checks: inactive transparency and activation opacity across day/night/reduced motion; Web/source JavaScript agreement.
- 16 native pixel checks: inactive doorway matches the scenery behind it by day and night; activated doorway replaces it with portal energy.
- Native cast, walk animation, town shop, guard and marina scenes inspected. Native day/night inactive and activated arch frames inspected.
- Existing regression-harness ObjectDB/resource warnings remain at shutdown; zero failed test assertions. Full browser gameplay and school-PC performance remain for manual testing.

## Files / manual upload

Deploy Server Update first, preserving server environment variables and persistent database storage. Then upload the Web ZIP to itch.io. Editable ZIP is the matching source. Nothing deployed automatically.

Selected original ImageGen sheets and exact prompts are in the editable source: assets/town230/*_source.png and tools/town230_prompts.json. The runtime uses assets/town230/citizens.png. See ART_SOURCES_V230.md for provenance and the reproducible atlas preparation tool.
