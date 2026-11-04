# Crossroads V280 — final main realm enemy movement

Completed and packaged SOURCE CANDIDATE. Native/browser gameplay validation is still pending. Nothing deployed or deleted.

## Scope
The Shattered Oath is the last outstanding main-progression realm after V279. Four trial areas, the splitting Gilded Usurper, Oath Shade and the Unwritten finale are covered. Thirteen new four-pose sets: Thorn Sentinel, Briar Matron, Cinder Salamander, Kiln Knight, Mirror Moth, Mirror Oracle, Storm Rook, Storm Archon, Gilded Usurper, Oath Shade, Unwritten Sovereign, Unwritten Ascendant and Unwritten Worldbreaker. The last two are transformed forms of the existing finale boss, not new encounters. Kiln Knight also uses the new presentation in The Between.

Each has idle, movement A, movement B and attack. Always neutral FRONT-facing: no side/back frames, mirroring, direction-indexed bodies or lateral running lean. Same restrained matte form depth as V279, bright readable midtones, selective coloured contours, one 40-colour palette shared across each character's poses. Preserve identity, equipment side, anatomy and original visible height/foot anchor. Generated using the built-in image-generation tool from existing identity references; exact prompts, all original sheets and before references are included under tools/release280.

Grounded enemies use alternate drawn support/step phases driven by actual world distance, with coordinating arms, leaf plates, tails or ceramic joints. Cinder Salamander is front-facing with diagonal four-leg phases and tail changes. Storm Rook articulates lower base supports without a new humanoid torso. Mirror Moth flaps its wings; other floaters articulate sleeves/armour/robe panels even while stationary. Grounded characters do not receive synthetic whole-body bob. Attack remains higher priority; aiming/projectiles stay independent of body facing.

## Recover editable source
V280 RecoveryDelta is CUMULATIVE OVER THE FOUR COMPLETE V278 EDITABLE PARTS. It includes the V279 changes and all originals/notes/tools. Do not apply the older V279 delta after V280. No standalone V280 source-part archives were created.

1. Extract all four saved V278 Editable parts into the SAME parent, merging Crossroads_Realms_Beyond.
2. Extract Crossroads_v280_RecoveryDelta.zip into that SAME parent, replacing files.
3. Open Crossroads_Realms_Beyond/project.godot in Godot 4.5.1 and import.

Required bases:

| Archive | Library ID | SHA-256 |
|---|---|---|
| Crossroads_v278_Editable_Part1.zip | libfile_6ffd51a687308191b621c32e0e226f82 | 883d1555982e718771648b7561ced90085ddc4c57d6555f87565a4a2636e3a75 |
| Crossroads_v278_Editable_Part2.zip | libfile_cd7f3e6aa12881918c5d25cfd49f9af5 | 6bf10ba204db96310e82f48e57eebe4c32bf8463c124ea5062464a6e93aa2a93 |
| Crossroads_v278_Editable_Part3.zip | libfile_b28256d1ee74819182d8670024976663 | 17f8781b8bca806c03182c3f61626c95a034e586a3168aff0173b508d8d42f97 |
| Crossroads_v278_Editable_Part4.zip | libfile_ee6d644f25888191ae456d97e42ab9e6 | 3ecc09c05733fbcfd312ae5392f68026ac39944989cb3b890666d9cbcc28dc83 |

The earlier V280 Working Recovery checkpoint version1 is a DIFFERENT, noncumulative patch over V279. Prefer the final RecoveryDelta above. Retain V279 delta + V278 parts as rollback; V274 remains the last actually runtime-validated release.

## Verification
20,507 STATIC checks pass. Five new/changed GDScripts parse. All 25 main-progression realm rosters checked, 168 identity appearances covered by retained V275–V279 sets plus this pass. Every new pose nonempty/distinct, binary alpha, no frame-edge clipping, shared palette and multi-part changes beyond rigid translation. All 20,182 unrelated baseline files byte-identical; only adapters/release/export/hub changed. Hero artwork, environment artwork, collision, AI/combat/stats, trial/finale mechanics, Usurper splits, saves, database and network protocol unchanged.

Final packaging verifies source/Web/Server byte identity for seven changed runtime files, PCK resource hashes, all final ZIP CRCs and EXACT source reconstruction from the four actual saved V278 parts plus cumulative V280 delta. Counts/hashes are in Crossroads_v280_Integrity.json.

Web/Server are incremental candidate packages made from saved V279 builds, not fresh Godot exports. Actual Godot 4.5.1 import/boot, Web boot, solo/co-op playthrough, live server/database and FPS tests NOT RUN: executables unavailable here. Do not call this runtime-validated. Run qa/v280_motion_check.gd after importing, then retained earlier QA. Play all four trials, all Usurper generations (1→3→9), Oath Shade summons, all three finale forms and The Between's Kiln Knight at normal scale, in solo and co-op. Check walking/stopping/attack recovery and equipment side consistency.

## Previews and next step
The GIF/PNG/HTML review show actual candidate atlas art, not gameplay footage. HTML offers movement/idle/attack, actual80px/1.5x/2x scale, half speed and pause. No hero/environment redesign is implied. This completes main-progression enemy artwork coverage; next step is an actual playtest, not inventing more realms.

Preserve live DEVELOPMENT_RECOVERY_HUB.md (libfile_bab654b363c4819198a9eb0d0b09ff78), all originals/prompts/notes, required bases and rollback. The source archive contains a pre-final registry snapshot; live hub supersedes it. SUBVEIL Site/source/latest Windows remain protected. Never delete automatically.
