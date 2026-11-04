# Crossroads V279 — modest depth and clearer enemy movement

Enemy-only candidate for Cinderheart Citadel, Crossroads High, Astral Rift, The Chimevault and Ebonwake Citadel.38 new four-pose sets plus6 retained shared enemies: Pencil Scrapper, Paper Sprite, Backpack Biter, Hall Monitor, Culture Blob and Cinderling. Includes Cinderheart's three wardens/Castellan/Calderax, High's three department bosses/all4 Final Exams, Chimevault's Gongbreaker/Silence Regent, Ebonwake's transformed Exalted Wraith and shared Astral creatures. Exact scope in tools/release279/roster.json.

User explicitly requests a SMALL increase in depth/detail above V278 without returning to glossy or over-detailed art. Soft-edged coarse pixel clusters, matte material shading, related midtones, soft form light and contact/overlap shade.40-colour per-frame ceiling instead of24; no change to actual in-game visible idle height. Each character retains its species, palette, silhouette, costume and established equipment side. Neutral FRONT head/torso in all4poses, both eyes visible where applicable; no directional body indexing, mirroring, side/rear poses or running lean. Heroes and previous realm art are unchanged.

New sets have idle, movementA, movementB, attack. Foot/paw/support/leg phases coordinate with arms, shoulders, robe/cape folds, antennae, wings or mechanical hinges. Crucible/GlassMatron/spider/beetle supports articulate. Gravel Skater pushes/skates on its existing board; no humanoid legs added to object enemies. Kiln Slug contracts body/foot folds and feelers.13 floating identities animate page leaves, chain links, wingbeats, rings, spikes, tails or ghost sleeves even at rest. Stationary Brood Reliquary remains speed0 and anchored: lid/rim/contents articulate in activity poses without moving its base. Attack frames take priority over movement. Directional projectile/telegraph aiming stays independent.

## Validation limits

Static/frame/route checks and actual package/source reconstruction results are recorded in Integrity. New/changed GDScripts parse. Four distinct nonempty80px frames per set, binary alpha/no surrounding glow, margins/idle-foot registration, original visible idle height and movement A/B pixel changes above the feet are checked. Existing gameplay/content/scenes/physics/stats/AI/combat/collision/navigation/saves/protocol/heroes/scenery/prior animations remain byte-identical outside explicit drawing/release/export/recovery metadata edits. Source/Web/Server changed runtime bytes and PCK hashes are verified. GIF/HTML use the actual candidate atlas; they are ARTWORK reviews, not live game footage.

Godot/browser executables are unavailable here. Native boot, actual solo/co-op realm playtests, server/database and FPS tests NOT RUN. V279 remains a saved-source candidate awaiting Godot4.5.1 import/runtime testing. V278 is the complete baseline/rollback for this update, V277 retained earlier rollback; V274 remains last previously runtime-validated release. Nothing deployed or deleted.

## Recover editable V279 — BASE REQUIRED

V279 RecoveryDelta and Working_Recovery are compact source PATCHES, NOT standalone projects. Every changed/new source file, all38 originals, exact prompts/before references, build/normalization/QA scripts and handoff are in the patch. Avoiding another full duplicated source tree preserves capacity while retaining exact reconstructibility.

1. Extract ALL FOUR saved V278 Editable ZIP parts (Part1,Part2,Part3,Part4) into the SAME parent to form Crossroads_Realms_Beyond.
2. Extract Crossroads_v279_RecoveryDelta.zip into that SAME parent, overlaying the shared project directory.
3. Open Crossroads_Realms_Beyond/project.godot in Godot4.5.1 and allow import.

Required V278 base IDs:
- Part1 libfile_6ffd51a687308191b621c32e0e226f82
- Part2 libfile_cd7f3e6aa12881918c5d25cfd49f9af5
- Part3 libfile_b28256d1ee74819182d8670024976663
- Part4 libfile_ee6d644f25888191ae456d97e42ab9e6

The package check reconstructs the source from these exact saved ZIPs plus the final delta, compares EVERY final project member by SHA256, and checks missing/duplicate base members and archive CRCs. Keep all4base parts while using this patch. Source archives contain earlier hub snapshots; current live hub owns final IDs and dependencies.

After import run:
`godot --headless --path Crossroads_Realms_Beyond --script res://qa/v279_motion_check.gd`
Run retained V278/V277/V276/V275 checks, then play all5 realms solo/co-op: walk/stop/attack, giant bosses, Cinderheart wardens/castellan/finalstage, all7 Highbosses and shared school enemies, Astral shared types, both Chimevault guardians, Ebonwake reviving/transformation/nest/healer actors. Check gear sides, normal-size movement readability and prior realm regressions. The native QA is supplied, NOT executed here.

Web candidate uses preserved V278 engine/autoload setup with changed raw scripts/assets and stale changed-script remaps removed. Server Update uses existing source-server workflow. Preserve environment secrets and use server-before-Web deployment only after testing; nothing is published.

## Continuity

Read CURRENT DEVELOPMENT_RECOVERY_HUB.md libfile_bab654b363c4819198a9eb0d0b09ff78 at every resumption. Never infer saved versions from chat claims. Protect V279 final patch plus ALL4V278 base parts, V277 rollback, all still-required older dependencies, every original art/style/prompt/handoff note, active SUBVEIL Site/source and latestWindows package. Save compact checkpoints after milestones/before long generation/export work. Never delete automatically. No further realm work without user request. Built-in imagegen used for new sheets; originals/prompts retained in tools/release279.
