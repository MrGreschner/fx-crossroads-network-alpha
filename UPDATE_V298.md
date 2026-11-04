# Crossroads V298 — Sovereign Depths / The Unwritten Crown

Hidden finale environment completed: Ash Processional, Ember Causeway, Memorial Walk, Last Chamber approach and Sovereign throne arena.32newscenerydesigns,129placements,6edge-matchedmaterials,31terrainpages. Broken crown arches, chained reliquaries, basalt/ivory memorials, bronze instruments, sun glass and a grand empty throne. Distinct stone surfaces, continuous platform edges with exposed cliff faces, low crown/star inlays, restrained lantern/candle/chime accents. Existing moving firelights and dark fog remain unchanged. Every raised prop stays outside the original walkable floor union. Party-aware fading,camera culling,12-page normal terrain cache and31-page spectator ceiling.

All nine original course floor rectangles and the2700x2100arena,24lava patches,21chasms,18movingfireballs,entry/chamber/arrival/throne/exit anchors and6200HPSovereign retained. Phase thresholds66%/33%,EmberProcession,Oathfall sanctuary sequence,three forms,all attacks/damage/cooldowns/authority/snapshots/completion remain original. Every original actor/art/content/scene byte retained; all original non-drawing functions and original fog/hazard/attack cues byte-identical. Only draw_ground presentation hook and release metadata changed. No record reset,deployment,live DB action or deletion. SUBVEIL untouched.

## Restore editable source

Extract ALL FOUR V278Editableparts,then final cumulativeV293RecoveryDelta libfile_9849168108cc8191a7cd3aa1602a2814,THEN finalV298RecoveryPatch. Patch includes294–298overEXACTV293; do not overlay older294/295/296/297patches afterward. Patch alone is not standalone. Open Crossroads_Realms_Beyond/project.godot. Exact savedV29721222-filebaseline was restored and hash-verified before this update;finalpatch reconstructs fullsource hash map exactly.

RollbackV297:samefourV278parts+V293delta+V297patch libfile_44bad43804388191b838c83328afdf2a. KeepV297Web/Server as rollback/build inputs. PermanentexactV281delta+fourbases and LegacySourceHistory remain protected. Keep originalart/prompts/notes/source/checkpoints/SUBVEIL. V298WorkingRecovery is unfinished and superseded.

## Verification and limits

6962native and6962softwareOpenGLfixturechecksPASS underGodot4.6.3. Static7208asset/scope/placement/floor/pagechecksPASS. Tests actualsolo+co-ophoststartup,entry/chamber/trueexit,originaltopology,static-hazard-safe path,originalillumination,lavacontactcooldown,6200HPand66%/33%thresholds,bothinterludes/allthreeforms,gueststate/authority,boundedhazards/cache and serializedstatepreservationduringrender.14enginecaptures inspected:12presentationfixtures(including2explicitlyunfoggedarchitecturecutaways)and2actualsoloscenedraws. Captures are not humanplaythroughs. Initial fixture RefCounted cleanup and double-fog draw issues were corrected; final render has no mesh-null or script errors. ExistingObjectDB/three-resource shutdown warnings persist.

Targetengine4.5.1 retained.Web/Server incremental from verified savedV297,notfresh4.5.1exports. Changedruntimebytes matchsource/WebPCK/Server;ZIPCRC/SHAand exactsourcereconstructionverified. Browser/realremote-co-op/classroomhardwareFPS/humanplaythroughpending. Originalgeneratedmasters/exactprompts/normalization/baseline/before-source/QA/package tools retained in tools/release298.

## Explicitly deferred itch.io issue

User requested this environment update FIRST and the upload-size fix AFTERWARD. The unchanged loader still loads one index.pck greater than200MB;V298Web is an oversized development candidate and will still be rejected by itch.io's single-extracted-filelimit. Do not present this as upload-ready or fixed. Next work: repair web packaging/loader and browser-verify it,without sacrificing game artwork/content. No need for a further environment update before addressing packaging.
