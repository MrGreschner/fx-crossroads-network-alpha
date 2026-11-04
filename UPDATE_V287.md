# V287 — Neon Crucible / Ironcore’s Lost Factory

User explicitly chose Neon Crucible. This environment pass builds on the verified saved V286 source. Crossroads High was not upgraded in this pass.

## Environment

40new scenery designs,177extra placements,40original machine-art replacements,six edge-matched materials and32terrain pages. Bolt Ironcore’s lore informs a worn bridge-building factory suspended above the aether: fabrication presses and saw cradles, bridge models/girders, memory archives, coolant pumps/tanks, Continuum receivers and uplink obelisks. A reclaimed repair garden and maintenance shelves contrast with the industrial complex.

The original40machines retain their exact visible rectangular footprints and original collision data. Additional tall structures sit on platform margins, with raised props fading near heroes. Flush patches/cables/vents and safety plates decorate open floors. Platform rims follow the union of the existing room/connector rectangles, keeping passage joins open visually. Background aether fragments drift beneath the decks; conveyors move, server indicators blink, coolant lines shift, and restrained machine steam/lamp accents animate. Native combat warnings, turret emergence, boss staging rings, wrecks, maintenance prompts, exit and cyan upload signal retain priority and behavior.

Soft coloured edges, matte coarse-pixel shading, restrained36colour prop palettes and quiet material contrast match the existing storybook style. Original masters and exact generation prompts are preserved. Whole-object segmentation fixed neighbouring fragments from uneven generated atlas gutters before final normalization. Built-in image generation used; no paid external provider or extra plugin.

## Preserved

6400×4800course,14room/connector rectangles,40originalpropanchors and solids,44authored spawns,4boss bodies(800/1000/1250/1700HP),2repairpods,all AI/homing missiles/hazards/repair/upload timings, actor artwork/poses, saves/economy/progression/records and protocol11/report schema3. All original gameplay methods and campaign/scene/content bytes are unchanged. No time-record reset. No deployment,liveDBoperation or deletion. SUBVEIL untouched.

## Verification

20580baseline sourcefiles audited;20574unchanged originals. Six original drawing/settings/release/description files changed, plus a current-hub snapshot in final source.40uniquecomplete36colour crops,177validplacements,6materialedge pairs,32PNGpages and original geometry signature checked. All47changedruntime files match source/WebPCK/Server.

Godot4.6.3 ran400native resource/footprint/navigation checks successfully. All40old visible machine rectangles match the new fitted art, and all51authored exit/boss/pod/enemy anchors remain standable/reachable. A separate24check actualsolo startup/four-body fixture passed with Bolt,44originalspawns,hidden turrets,original bossHP,2.5second uploads and final done state. This fixture advances local boss state directly; it is not a real combat playthrough or live account settlement. No script errors. Smoke shutdown reports ObjectDB leaks and3resources still in use, also observed duringV286; not investigated in this environment pass.

Visible/native combat playthrough, browser, co-op, live server/database and hardwareFPS were NOT tested. PNG/GIF previews compose actual runtime artwork at authored geometry; they are NOT engine screenshots. The GIF illustrates conveyor timing only. Project target remains Godot4.5.1. Web/Server are incremental candidates from hash/CRC-verified V286 packages, not fresh engine exports; export templates are absent here. Before deployment, import in4.5.1, run qa/v287_neon_check.gd and qa/v287_neon_smoke.gd, play solo/co-op through pods/turrets/allfourbodies/merchant/exit and make coordinated fresh exports. Earlier prepared Lantern Marsh-only record migration remains unchanged.

## Recovery

Extract ALL FOUR V278 Editable base source ZIPs into one parent, then ONLY the final cumulative V287 RecoveryDelta into that same parent. This creates Crossroads_Realms_Beyond/project.godot and includesV279–V287. The delta is NOT standalone. Exact required source-part IDs/hashes, reconstructed source file count and archive receipts are in Crossroads_v287_Integrity.json. Older deltas must not be overlaid afterward.

Rollback: finalV286delta with those same four bases. Keep V286Web/Server as incremental build inputs. Permanently protect exactV281delta+fourbases while LegacySourceHistory references them. Preserve all notes, style/prompts/originalart and SUBVEIL’s canonical Site/source and latest Windows package. The early V287WorkingRecovery is noncumulative overexactV286 and superseded by final source.

All new original masters/exact prompts/normalization/placement/signature/build/preview/validation tools live in tools/release287. Current DEVELOPMENT_RECOVERY_HUB.md(libfile_bab654b363c4819198a9eb0d0b09ff78) supersedes snapshots inside source archives. Next realm afterNeoninmanifest is Cinderheart; CrossroadsHigh remains unmodified by this pass. Begin another realm only when requested.

Pre-final-upload storage: estimated11,381,033,216knownbytes across2218deduplicatedfiles,12fullypaginatedpages. Five file sizes are unavailable and no authoritative account quota meter is exposed. Exact billed usage and definitive80%status cannot be confirmed. No save/quota error and no deletion.
