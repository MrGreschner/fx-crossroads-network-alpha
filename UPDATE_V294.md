# V294 — Astral Rift: The Lost-Star Observatories

Textures and scenery only. Vesper’s established lore—a bat courier carrying lost stars between broken observatories—now appears in ruined telescopes, courier roosts, celestial post, star charts, brass instruments, moonstone ruins and floating islands.

32 distinct scenery designs,154placements,6materials and22terrainpages. Original24circular obelisk anchors and three large observatory instruments are represented by new art. Extra raised scenery sits outside walkable lanes except the three observatory furniture groups; these fade near heroes. Small flat fragments decorate lane edges. Stars drift through the void; lanterns shimmer and instruments have slow contained orbital glints. Page culling and18-page normal cache,22-page spectator ceiling. Matte coarse pixel shading with36colour prop ceiling and nearest filtering.

All seven floor polygons,45scene enemy anchors and eight existing additional encounter foes,all24collider circles,original spawn/return/merchant/boss positions,all enemies/heroes/animations/attacks/stats,progression,saves and community records are retained. No record reset is needed because routes and gameplay geometry are unchanged. Protocol11/report schema3 retained. Nothing deployed or deleted; SUBVEIL untouched.

## Restore editable source

This release intentionally uses a compact noncumulative PATCH to avoid duplicating the existing source history. Restore ALL FOUR V278 Editable parts,then final cumulative V293 RecoveryDelta libfile_9849168108cc8191a7cd3aa1602a2814,then Crossroads_v294_RecoveryPatch.zip into the same parent. V294 patch ALONE is not standalone and does NOT replace the required V293 delta. Preserve all dependencies. Use V293 with the same four bases as rollback. The live DEVELOPMENT_RECOVERY_HUB.md supersedes historical snapshots inside old archives.

## Validation

Verified all20,914baselineV293files against saved archive hashes/ZIP CRCS before work. Original assets/content/scenes and actor art unchanged byte for byte. Four original presentation/version files changed; new renderer/assets/tools/QA added.60asset/material/page checks and1,259connected100unitfloor-grid samples passed.255actualGodot checks passed under4.6.3,including solo start,co-op host start/four-body draw,all32textureloads,22terrainpages,original anchors/accessible endpoints,void blocking,boundedtexturecache and unchanged combat/geometry state during rendering. Same255checks passed with actual softwareOpenGLrendering,seven native fixture captures. Captures show the real new renderer with retained Vesper/Rift Weaver art; they are fixtures,not human playthroughs. Existing ObjectDB/three-resource shutdown warnings remain.

Web/Server packages are incremental from successfully saved V293 builds; changed runtime bytes are compared against source and each other. Target remainsGodot4.5.1; no fresh4.5.1export,browser session,real remote co-op session or classroom hardware FPS measurement. Importing/reviewing source usesGodot4.6.3 locally. Install matching Web and Server packages together. Human playtesting remains required before deployment.

Original generated masters,exact prompts,normalization/placement recipes,before source,baseline and validation tools/logs are retained under tools/release294. Built-in image generation was used; no extra plugin installation or paid external asset jobs were needed.
