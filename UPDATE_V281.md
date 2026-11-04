# Crossroads V281 — Orbital Breach environment

Completed SOURCE CANDIDATE. Actual Godot/browser gameplay testing remains pending. Nothing deployed or deleted.

## Scope and identity
Environment sequence resumed after V274 Crossbell Middle School. V275–V280 enemy work is retained. Orbital Breach now feels like a weathered orbital station: navy steel, faded ivory ceramic, muted brass utility routes and desaturated teal safety glass. Broad walkable observation galleries flank the existing central route, with star views under the glass. Five visual bays: Arrival Lock, Observation Array, Life Support, Salvage Works and Signal Chamber.

32 distinct scenery designs, 115 placements: 24 raised hardware designs assigned to all 45 ORIGINAL satellite obstacle anchors, plus eight flush inset designs in 70 placements. Six deck materials, baked into five retained 820×725 pages covering the unchanged 8200×1450 world at 2× scale. A 2560×1280 shared atlas supplies raised machinery. All assets use soft coloured contours and matte environmental shading. No new enemies or characters were generated. Built-in image generation supplied five original master sheets; exact prompts, originals, normalization/baking tools and geometry references are in tools/release281.

Scenery includes communication receivers, antennas, solar masts, beacons, mooring clamps, cargo, pressure/coolant tanks, reactor coils, condensers, batteries, air scrubbers, oxygen terrariums, gyro hardware, consoles, storage/repair props, flush hatches, inspection covers, observation panels and the flush boss-arena medallion. Signal lights, small equipment arcs and restrained cable/window glints animate in the environment only. Props and pages are culled; raised scenery fades when a hero is underneath its painted overhang. No added lights, dynamic image generation or per-frame PNG decoding.

## Preserved
Every previous enemy/hero asset and animation script is byte-identical to saved V280. Only game.draw_world and arcade._draw_world changed among their existing methods; actor drawing/input/simulation/save/commerce methods are identical. Original space scene and region/encounter data unchanged: 45 radius-42 obstacle anchors, 68 enemy spawns, 1130HP Signal Core, spawn (250,725), return gate (90,725), merchant (4100,725), boss (7900,725). Existing merchant artwork/behavior unchanged. New floor details are flush and walkable; raised machinery stays on existing solid anchors and its base width fits the original collision diameter. No new hazards, barriers, enemy behavior, altered time records, economy, cloud saves or protocol changes. Other realms remain unchanged.

## Recover editable source
The FINAL Crossroads_v281_RecoveryDelta.zip is CUMULATIVE OVER ALL FOUR COMPLETE V278 EDITABLE PARTS. It includes V279, V280 and V281 changes and original artwork. It is not standalone; no separate V279/V280 overlay is needed after it.

Extract all four V278 ZIPs into the SAME parent, then overlay the final V281 RecoveryDelta into that SAME parent, producing Crossroads_Realms_Beyond/project.godot. Use Godot 4.5.1.

| Base archive | Library ID | SHA-256 |
|---|---|---|
| Crossroads_v278_Editable_Part1.zip | libfile_6ffd51a687308191b621c32e0e226f82 | 883d1555982e718771648b7561ced90085ddc4c57d6555f87565a4a2636e3a75 |
| Crossroads_v278_Editable_Part2.zip | libfile_cd7f3e6aa12881918c5d25cfd49f9af5 | 6bf10ba204db96310e82f48e57eebe4c32bf8463c124ea5062464a6e93aa2a93 |
| Crossroads_v278_Editable_Part3.zip | libfile_b28256d1ee74819182d8670024976663 | 17f8781b8bca806c03182c3f61626c95a034e586a3168aff0173b508d8d42f97 |
| Crossroads_v278_Editable_Part4.zip | libfile_ee6d644f25888191ae456d97e42ab9e6 | 3ecc09c05733fbcfd312ae5392f68026ac39944989cb3b890666d9cbcc28dc83 |

Keep V280 cumulative delta + those four bases as rollback. V274 remains the last actually native/browser-runtime-validated release. Earlier V281 Working Recovery version1 is a noncumulative checkpoint over V280; prefer final cumulative V281 delta. Preserve V280 Web/Server as bases for the supplied incremental build script, all still-needed earlier dependencies, all handoff/style/prompt notes and original art. SUBVEIL Site/source/latest Windows stay protected.

## Validation and limitations
31,979 STATIC checks pass, including 11,520 unchanged circular-obstacle sample comparisons, all 32 distinct complete artwork crops, all 115 placements, collision-base fitting, material/page dimensions and immutable original file hashes. Only the two named environment drawing functions changed in game/arcade. Five actual runtime/QA GDScripts parse, plus three source/reference copies. 20,229 unrelated V280 baseline files byte-identical. Source/Web/Server byte identity verified for all 19 changed runtime resources, with PCK entry hashes. All three final ZIP CRCs checked and exact source reconstruction verified from the four actual saved V278 source ZIPs plus final cumulative delta; counts/hashes are in Integrity.

Web/Server are incremental candidate packages from saved V280 builds, not fresh Godot exports. Native Godot4.5.1 import/boot, browser boot, actual solo/co-op playthrough, live server/database and hardware FPS tests NOT RUN: those executables are unavailable here. Do not call this runtime-validated. Run qa/v281_environment_check.gd after importing, then retained previous QA and real solo/co-op tests. Check normal-camera deck visibility, all 45 solids, read-through/fading at machinery, every enemy/boss animation, merchant access, portals/exit, aiming cues and performance on school hardware.

The PNG/GIF previews are layout/asset renders from actual candidate imagery and original scene anchors, not Godot gameplay captures or performance evidence. Enemy art in the layout preview is unchanged V277 Orbital artwork, shown only for scale/readability. The GIF demonstrates scenery accents with no enemy animation changes.

Next environment realm, only when requested: Hollow Quarantine (zombie). No further enemy/hero/style work implied. The live DEVELOPMENT_RECOVERY_HUB.md (libfile_bab654b363c4819198a9eb0d0b09ff78) supersedes the pre-final registry snapshot inside the source archive. Never delete automatically.
