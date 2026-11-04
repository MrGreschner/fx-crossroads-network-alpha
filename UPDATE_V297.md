# Crossroads V297 — The Shattered Oath / Four Seals

Main environment pass: Briar Reliquary, Cinder Causeway, Mirrorfrost Gallery, Stormglass Spire, Fractured Nexus and Usurper Court.32scenerydesigns,329placements,6edge-matched materials,77terrainpages. Thorn altars/urns/vines, kiln/forge/braziers, cracked mirrors/chime lights, storm instruments, memorials/banners/broken throne. Original115sceneanchors receive new presentation at exact original positions. Small contained lamp/glass/banner accents, clear labels and retained portal/trap cues. Raised scenery fades near any party member. Normal terrain cache18pages with camera culling; spectator ceiling77.

Allsixmainfloorareas,eightdividerwalls,36solidobstacles,16timedtraplanes,portals,merchant/spawn/return anchors and everyoriginalscene/content/actorart byte retained. Allnon-drawingfunctions in changed scripts remain byte-identical. The original18foes+guardian per trial,850/980/1110/1240guardianHP,1300HPUsurper and1-to3-to9split,XPtheft/restore and hiddenfinalegate remain original. Enemy/hero animations/combat/economy/save/records unchanged. No record reset, deployment or live DB action. SUBVEIL unchanged. HiddenSovereigndepths still have their previous environment; final environmental pass can follow on request.

## Restore editable source

Extract ALL FOUR V278Editableparts, then final cumulativeV293RecoveryDelta libfile_9849168108cc8191a7cd3aa1602a2814, THEN V297RecoveryPatch. This patch includes294–297overEXACTV293; do not overlay older294/295/296patches afterward. Patch alone is not standalone. Open Crossroads_Realms_Beyond/project.godot. Actual saved baseline plus patch reconstructs the exact source hash map; integrity JSON records count/hashes.

RollbackV296: samefourV278parts+V293delta+V296patch libfile_633d15fd32fc8191b6518abe318b5589. KeepV296Web/Server as incrementalbuild inputs/rollback. PermanentexactV281delta+fourbases and LegacySourceHistory protected. Allnotes/styles/prompts/originalart/checkpoints/sourceparts andSUBVEIL retained. V297WorkingRecovery is superseded and unfinished.

## Verification and limits

5332native and5332softwareOpenGLfixturechecksPASS underGodot4.6.3. Static559asset/scope/placement/pagechecksPASS. Tests actualsolo+co-ophoststartup,allfourtrialportals/rosters/guardianHP,originaltraversabilitysamples/dividerboundaries,16traps,Usurpergateand1/3/9split throughhiddenexit,sceneanchorretention,normalcache and originalstatepreservationduringrender. Eleven realrenderer fixturecaptures cover allsixareas and trapcrossings;existinghero/enemyart shownatnormalgamplayscale. Captures are not humanplaythroughs. Source/WebPCK/Server runtimebytesmatch,ZIPCRC/SHAandexactsource reconstructionPASS.

Targetengine4.5.1 retained. Web/Server are incremental candidates from verified savedV296, not fresh4.5.1exports. Browser/realremote-co-op/classroomhardwareFPS/humanplaythrough pending. Existing ObjectDB/resource shutdown warnings persist. An initial test started before imports finished and was stopped due missing import resources; final QA ran after completed import. Original generated masters and exact prompts plus normalization/placement/baseline/before-source/QA/package tools retained in tools/release297. No additional plugin required.
