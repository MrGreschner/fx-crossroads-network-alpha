# Crossroads V296 — Ebonwake Citadel / The Forbidden Ledger

Environment upgrade grounded in Veyra Spellthief's existing exile/forbidden-ledger lore. Five districts above the black sea: Sea Gate, Unquiet Infirmary, Brood Reliquaries, Chrysalis Forge and Last Court.32distinct scenery designs,229placements,6edge-matched materials,38terrainpages. Grand facades and ledger throne, infirmary beds/screens/medicine, empty roosts and raven statues, chrysalis forge equipment, court folios and coffers. Restrained cosmetic sea glints, ward lamps, ember highlights and banner accents. Readable district labels, party-aware prop fading, camera culling and18-page normal terrain cache.

All11original floor rectangles,8pillars,26authored enemy anchors, spawn/return/merchant/final boss anchors and existing bridge connections retained. Only one early presentation hook added to original v43_expansion.draw_world; all other original source bytes of that script remain intact and old drawing remains a geometry-mismatch fallback. Enemy/hero art and animations, encounters/AI/attacks/HP, economy, saves, protocol11/schema3, time records and other realms are unchanged. No new unit; no live reset, deletion or deployment. SUBVEIL unchanged.

## Recover editable source

Extract ALL FOUR protected V278 Editable parts into one parent, then final cumulative V293RecoveryDelta libfile_9849168108cc8191a7cd3aa1602a2814, THEN Crossroads_v296_RecoveryPatch.zip into the same parent. V296patch includes V294,V295andV296 over EXACT V293. Do not add separate V294/V295 overlays afterward. Patch alone is NOT standalone. Open Crossroads_Realms_Beyond/project.godot. Package integrity JSON records file hashes and exact reconstruction count.

Rollback: fourV278parts + finalV293delta + finalV295patch libfile_8be5cfd282088191932920b324dc8393. Keep V295Web/Server as this update's build inputs and rollback pair. ExactV281+fourbases remains permanent LegacySourceHistory dependency. Keep all handoffs/style/prompts/original art/source dependencies and SUBVEILSite/source/latestWindows. WorkingRecovery version1 is superseded and predates final junction fitting/QA.

## Verification and limits

3006native and3006softwareOpenGL fixture checks passed under Godot4.6.3. Static305asset/scope/page checks passed. Tested actual solo and co-op host startup, original26-foe roster, sampled collision boundaries, spawn/merchant/return/boss anchors, original boss gating/2400HP, JSON snapshot and actualdraw callbacks. Nine software-rendered camera previews cover five districts and bridges; these are renderer fixtures, not a human playthrough. Every original asset/content/scene byte is preserved. Changed runtime source/WebPCK/Server bytes match; ZIP CRC/SHA and exact source reconstruction checked.

Target engine remains Godot4.5.1. Web/Server are incremental candidates from verified savedV295 archives, not fresh exports. Browser launch/playthrough, real remote multiplayer, classroom hardware FPS and human combat navigation remain pending. Existing ObjectDB/resource shutdown warnings remain. No browser/native FPS equivalence claim.

New original masters, exact prompts, preparation and package/QA scripts, baseline and before-source are retained in tools/release296. RawPNG renderer uses nearest filtering;32asset palettes capped at36colours, material edges match. No additional app/plugin was required. Next manifest environment after Ebonwake is Shattered Oath, only when requested.
