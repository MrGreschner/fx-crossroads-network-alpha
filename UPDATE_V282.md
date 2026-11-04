# Crossroads V282 — logical merchant carts + Hollow Quarantine environment

SOURCE CANDIDATE, saved only when the live recovery registry confirms every upload. Native Godot/browser gameplay testing remains pending. Nothing deployed or deleted.

## Merchant carts
One shared simpler matte coarse-pixel ram wagon replaces the previous ornate realm carts. Its long broadside service window faces the player; both pulling shafts extend from its right-hand front, perpendicular to the counter. Two visible wheels, plain teal canopy, cream ram, two potions and a sack. The original generated master and exact prompt are retained. Runtime canvas160×96,47visible palette colours, nearest filtering, shown in a240×144world rectangle. A shared cached texture is reused.

All13existing cart service routes now use this artwork, including Sunfield and Frostbound's separately drawn carts. Other existing solo realm merchant drawings use it as well. Town merchant remains unchanged. Original shop positions/support/radii, purchases/prices, inventories and network authority are unchanged. No added co-op shops. Folded Coast retains the normal outsider merchant exception to its paper-world lore.

## Hollow Quarantine
The next environment realm after Orbital Breach is zombie / Hollow Quarantine. A weathered medical quarantine cordon, with mossy cream paving, broken clinical tiles, rusty drains, cracked asphalt, roots, ochre ribbons and restrained fungal growth. Five visual districts: Arrival Cordon, Triage Ward, Filterworks, Reclaimed Ward, Director Checkpoint.

32distinct scenery designs in125placements:24raised equipment designs reuse ALL45original radius42solid anchors, plus eight flush ground-detail designs in80placements. Raised bases fit inside original collision footprints. Six edge-matched materials are baked into five850×725floor pages drawn at2×scale across the unchanged8500×1450field. A1280×640atlas holds160×160prop cells. Pages/props are culled; raised artwork fades when a hero overlaps its overhang. A few contained warning lamps, ventilation strokes and sparse edge motes animate, with no full-screen fog, lights, shaders or particle nodes. One Director floor emblem appears only at the final checkpoint.

Scenery includes cordon lamp, folded barricade, checkpoint post, decontamination post, supply crate, medicine cabinet, sample canister, air-filter column, wash station, sterilizer, stored stretcher, privacy screen, oxygen rack, drip stand, waste bin, generator, spore stump, fungal planter, rooted pipe, water tank, incubator, vent stack, emergency radio and Warden locker; ground details include grates, mosaic, fallen ribbon, spore crust, papers, maintenance cover, medical mat and Director emblem.

All76authored scene enemy spawns, later scripted encounters including Warden/hidden Aberration,1500HPDirector,spawn(250,725),return(90,725),merchant(4250,725),boss(8200,725) and every existing actor/animation/combat/content/scene/save file remain unchanged. No new barriers, hazards, time-record reset, gameplay or economy changes. Other realm scenery changes only at existing merchant cart drawings.

## Restore editable source
Final Crossroads_v282_RecoveryDelta.zip is CUMULATIVE OVER ALL FOUR COMPLETE V278 EDITABLE PARTS. It includesV279,V280,V281 andV282 code/artwork. It is a patch, not standalone. Extract all four bases into the SAME parent, then overlay this delta into that SAME parent to produce Crossroads_Realms_Beyond/project.godot. Godot4.5.1. Do not overlay older deltas afterward.

| Base | Library ID | SHA256 |
|---|---|---|
| V278Part1 | libfile_6ffd51a687308191b621c32e0e226f82 | 883d1555982e718771648b7561ced90085ddc4c57d6555f87565a4a2636e3a75 |
| V278Part2 | libfile_cd7f3e6aa12881918c5d25cfd49f9af5 | 6bf10ba204db96310e82f48e57eebe4c32bf8463c124ea5062464a6e93aa2a93 |
| V278Part3 | libfile_b28256d1ee74819182d8670024976663 | 17f8781b8bca806c03182c3f61626c95a034e586a3168aff0173b508d8d42f97 |
| V278Part4 | libfile_ee6d644f25888191ae456d97e42ab9e6 | 3ecc09c05733fbcfd312ae5392f68026ac39944989cb3b890666d9cbcc28dc83 |

Rollback: exact V281 cumulative delta libfile_b44643c3cce881919542a13d7a16ee74 plus those same four bases. Keep V281 Web/Server as incremental build inputs. ExactV281 must ALSO remain protected indefinitely because Crossroads_Legacy_Source_History.zip references those original file contents. V274 remains last actually runtime-validated release; preserve its source/builds and all current protected dependencies in the livehub. SUBVEIL active Site/source/latestWindows untouched.

The early V282 Working Recovery is an incomplete checkpoint OVERV281: it omitted the runtime quarantine_art282.gd at the project root and predates fitting/texture corrections. DO NOT use it instead of the final cumulative delta. Final packaging includes the missing renderer and all corrections.

## Validation and remaining checks
Static source audit compares all20,275V281baseline files, allowing only nine scoped original files plus the hub snapshot. All original assets/content/scenes remain byte-identical. Parsed7actual runtime scripts plus the new QA script. Verified all32unclipped distinct crops, alpha,47-colour cart,45solid-foot registrations,125placements,six edge-matched material tiles and five page sizes. Only game.draw_world/draw_sprite,arcade._draw_world and the three scoped cart/environment drawing functions changed; no actor/simulation methods changed. All25new/changed runtime resources match editable source, Server and Web PCK byte-for-byte. Final ZIP CRC and exact four-base-plus-delta source reconstruction are checked by package.py; see Integrity for the final counts/hashes.

Web/Server are INCREMENTAL candidate packages from saved V281, not fresh Godot exports. Godot/browser executables are unavailable here: native import/boot, real browser boot, solo/co-opplaythrough, live server/database and schoolhardware FPS NOTRUN. Run Godot4.5.1 import, then qa/v282_environment_check.gd and retained qa/v198_29_quarantine.gd. Play all13cart locations in solo/co-op; ensure exactly one cart, correct labels, no stale building/cart overlap, shop interaction and clear counter access. Traverse Hollow Quarantine's upper/lower areas, verify all45solids,overhangfading,enemy animations/boss/surprise miniboss,merchant,return/finalportal and combat warning visibility. Test normal-camera and schoolhardware rendering cost.

PNG previews are actual asset/layout renders with unchanged V278 enemy frames for scale, not Godot gameplay captures. Built-in image generation created the six originals; prompts/masters/normalization/build/validation tools are in tools/release282.

Next environment, only when requested: Lantern Marsh. No enemy or hero update implied. The canonical live DEVELOPMENT_RECOVERY_HUB.md supersedes the pre-final snapshot in source archives.
