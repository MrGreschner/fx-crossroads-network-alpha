# V286 — Brasslock Borough: City of Every Lock

Environment update built on the verified saved V285 source. Nera Lockstep’s established lore—lantern courier, enchanted keys, impossible routes and a ghostly last tram—guides this realm’s presentation.

## What changed

- 32 new scenery designs and185placements: locksmith benches/key cabinets, parcel sorting/mail cabinets, archive furniture, clockmakers, tea/bakery counters, pipes/boilers, ivy/flower baskets, street furniture and tram stops.
- Six gently shaded materials: slate cobbles, limestone pavements, walnut parquet, teal tiles, cutaway masonry and subdued civic key mosaics. Ground contrasts were softened after visual review for combat readability.
- Fifteen named, furnished cutaway buildings retain their two-room layouts. Courier houses, keyworks, workshops, libraries, tea rooms, a depot and the courthouse express the borough’s lore.
- A cosmetic ghost tram follows the southern street; lanterns pulse gently, stove/boiler steam rises and small clock accents move. The tram is scenery: no new transport, hazards or combat units.
- Raised props fade when a hero overlaps. Door leaves, interaction hints, summoned secret passages and eruption warnings retain their existing drawing/behavior.
- Fixed one inherited, truncated V284 Marsh PNG using its preserved exact recipe. Three independent neighbouring terrain pages matched pixel-for-pixel before replacing the damaged page. Original Marsh geometry and art design remain intact.

## Preserved

Original3840×2560course,15buildings,45doors,120wall segments, all enemy markers, boss/merchant/spawn/return points, collision, navigation, door occupancy, rifts and enemy tactics. Every original hero/enemy artwork file, pose, content definition, scene, combat/save/progression/record system remains byte-identical. No time-record reset. No deployment/liveDB operation/deletion. SUBVEIL untouched.

## Validation and limitations

20548baseline files audited; seven scoped original runtime/settings/description/repair files changed, plus the recovery-hub snapshot in final source. Original city gameplay methods are byte-identical.32unique complete32-colour crops,185validplacements and six edge-matched materials checked. All15changedruntime resources match source/WebPCK/Server bytes.

Godot4.6.3 is available in this session.353native checks passed for resources,45closed/open doors, all30reachable rooms, spawn/return/merchant/boss and repaired PNG. Actual main scene boot and solo Brasslock startup with Nera/existing enemies/active city clock passed without script errors. Main-scene/smoke exits report ObjectDB leaks and3resources still in use; these shutdown warnings were not investigated in this environment pass. Original project/export target remains4.5.1.

Visible native rendering, browser, multiplayer, real combat/course completion and hardware FPS were NOT tested. PNG/GIF deliverables are compositions of the actual runtime assets and authored layout, not engine screenshots. The GIF illustrates tram travel; game clocks/steam/lamps run in the actual drawing code.

Web and Server packages are incremental candidates from hash/CRC-verified V285 packages, with a matching new source payload; they are NOT fresh Godot exports. Export templates are not installed here. Before deployment, import editable source in Godot4.5.1, run qa/v286_brasslock_check.gd and qa/v286_brasslock_smoke.gd, inspect real solo/co-op gameplay/doors/rifts/merchant/exit and make a coordinated fresh export. Preserve the earlier prepared Lantern Marsh-only migration; this update introduces no reset.

## Source recovery

Extract ALL FOUR V278 Editable source parts into one parent, then ONLY the FINAL CUMULATIVE V286 RecoveryDelta into that same parent. This produces Crossroads_Realms_Beyond/project.godot and includesV279–V286. The delta is NOT standalone. Do not overlay older deltas afterward. Exact required base hashes are in Crossroads_v286_Integrity.json.

Rollback: final V285 cumulative delta with those same four bases. Protect permanent LegacySourceHistory dependencies: exactV281delta plus those bases. Keep older protected handoffs/art/style notes and SUBVEIL source/Windows package. The early V286WorkingRecovery applies over exactV285, is noncumulative and superseded by final source.

Original generated masters, exact prompts, normalization/placement/build/repair/preview/validation tools and checks are retained in tools/release286. Built-in image generation was used; no paid external generation or additional plugin. Read current DEVELOPMENT_RECOVERY_HUB.md(libfile_bab654b363c4819198a9eb0d0b09ff78), whose live registry supersedes snapshots inside archives.

Next environment in manifest progression: Crossroads High (high_school), only when requested. Enemies/hero styling stays unchanged unless explicitly requested.

Storage before new packages: estimated10,748,846,237knownbytes across2205deduplicated files,12completepages;5unreported sizes. No authoritative meter exposed. Exact billed usage and definitive80%status cannot be determined. No deletion. Preserve originals/dependencies.
