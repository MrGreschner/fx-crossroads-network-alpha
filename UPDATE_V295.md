# V295 — The Chimevault: The Buried Choir

Environment textures and scenery only. The established buried cathedral of cracked bells now has three distinct visual floors: patinated teal stone and weathered bells in Echo Vestibule; warm limestone, soot and bell-casting furnishings in Bell Foundry; quiet plum marble, pale brass, organ pipes and ceremonial furnishings in Silent Crown.

32 distinct scenery designs,153placements,6materials and27terrainpages. Five grand architectural designs retain larger196pixel art. Raised props sit entirely on existing blocked wall cells; small flat medallions and low lift-platform illustrations sit on open floor. Nearby hero fade preserves visibility. Contained lantern glints, chime highlights and small wall-bound echo glints remain cosmetic. Existing lift labels, completion pointer and enemy attack telegraphs are retained. Normal cache18terrainpages;spectatorceiling27;props/pages culled by camera.36-colour prop ceiling,nearest filtering,matte coarse pixel shading.

All original maze seeds,302open cells across three floors (102/101/99),everyblockedcell,pathfinding,guardianrooms,liftpositions andclear-before-lift rules remain unchanged. Stage rosters remain11/11/12;original enemy and hero art/animation/attacks/stats,all progress/saves/economy/records retained. No time reset. Protocol11/report schema3 retained. No deployment,deletion or liveDB write;SUBVEIL untouched.

## Restore editable source

Extract ALL FOUR V278 Editable parts into one parent,then final cumulative V293 RecoveryDelta libfile_9849168108cc8191a7cd3aa1602a2814,THEN Crossroads_v295_RecoveryPatch.zip into that same parent. This patch includes BOTH V294 and V295 changes over exactV293,so a separate V294 overlay is unnecessary for the latest source. It is not standalone and does not replace the required V293 delta. Do not apply the olderV294patch afterward. Exact source reconstruction is verified against saved baseline hashes. The live DEVELOPMENT_RECOVERY_HUB.md supersedes archived snapshots.

Rollback V294: four V278parts+V293delta+V294patch libfile_2c363a6dc34c8191ba9e46558d4d17b2. KeepV294Web/Server as build inputs/rollback. All required older source/history dependencies remain protected.

## Validation and limits

Recovered and verified all20,968V294baselinefiles from actual saved archives with SHA256/CRC checks. The only Chimevault source change adds one presentation hook at draw_world; original gameplay functions remain byte-identical. Project/build versions updated. Every original asset,content file andscene remains byte-identical.

218static checks cover all32unclippedpalette-limitedsprites,exacttileedgematching,all153placementreferences andwallfootprints,27page reconstruction,andall302openmaze cells reachable from their entrances.3667actualGodot checks pass under4.6.3: baseline navigation comparisons at3315cell-centre/corner samples,solo start andallfloorrosters,liftsealing/advancement,JSONmazereconstruction,alltextureloads,geometrysignaturefallback,drawstatepreservation,boundedcache andco-ophost/four-body rendering. The same3667checks pass under softwareOpenGL/llvmpipe with nine native renderer fixture captures. Capture character samples are placed on open cells; fixtures are not human playthroughs.

Initial atlas-grid cropping included a few neighbouring-object fragments. Final normalization uses complete connected object silhouettes instead; original masters are retained. A display-number collision during a repeat capture was resolved using a fresh display number. Final native/render logs pass. Existing ObjectDB/three-resource shutdown warnings persist.

Web/Server are incremental from successfully savedV294 builds,with changed runtime bytes compared against source and each other. Target remainsGodot4.5.1; no fresh4.5.1export,browserplaythrough,real remote co-op session or classroom hardware FPS measurement. Install matchingWeb/Serverpackages together;human playtesting remains required before deployment.

Original built-in-generated art masters,exact prompts,normalization/placement/geometry-export recipes,before source,baseline andQA tools/logs are retained under tools/release295. No additional plugin installation or external paid asset jobs were needed.
