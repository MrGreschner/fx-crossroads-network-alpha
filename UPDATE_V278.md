# Crossroads V278 — enemy movement in five requested realms

Enemy-only candidate for Hollow Quarantine, The Lantern Marsh, Silverfall Reach, Brasslock Borough and Neon Crucible.43 new four-pose identities cover the main rosters plus six additional Marsh/Silverfall encounter actors. Brasslock's shared Amber Hornet retains its V276 upgrade. Neon includes all four Continuum boss shells and Fork Runner summons; Brasslock includes summoned Latch Hounds. The roster file records the exact scope.

Every new set has idle, movementA, movementB and attack. Grounded creatures coordinate planted/lifted feet, paws, roots or jointed legs with arms, sleeves, capes, antennae, tails and other body parts. Root/branch creatures articulate roots and branches. Crabs/spiders/beetles use their existing leg pairs and claws. Ripple Eel changes its S-curve and fins. Ten floating creatures use flame fins, water ribbons, wings, rotors, cable tails, panel hinges or ring segments while remaining objects/spirits. No humanoid limbs are added to floating objects. Frontal attacks remain independent of projectile aiming.

Keep the early coarse-pixel style: matte bright midtones, restrained palette, selective coloured edges and readable simple shapes. Neutral head/torso face forward in every pose; no direction-indexed bodies, side/rear turns or mirroring. Equipment stays on its established side. Original visible idle height and foot registration are retained. Grounded animation uses the existing traveled-distance gait/stop state, without a synthetic whole-body walking bounce. Floating parts also animate at idle. Both the Quarantine Hound and Latch Hound were corrected to centered frontal stances; rejected side/three-quarter masters are retained as original art, not selected for the game.

## Checks and limits

Static validation records actual passed checks: roster coverage, four distinct nonempty frames per set, alpha/margins, preserved visible size, pixel changes above the feet, attack priority, presentation routes and preservation of old files outside the explicit release/drawing/hub allowlist. New/changed GDScripts parse. Source/Web/Server changed runtime bytes and PCK entry hashes are compared. Package ZIP CRCs and all complete source members are verified. The GIF and interactive HTML use the actual candidate atlas; they are artwork reviews, not live gameplay footage.

Native Godot/browser runtime playtests have NOT been run here because those executables are unavailable. V278 is a saved-source candidate awaiting import/runtime tests. V277 is its complete candidate baseline/rollback; V274 remains the last previously runtime-validated release. No hardware FPS/live co-op/server/database claim. Nothing deployed or deleted.

Heroes, existing scenery/textures, scenes/content, collision/navigation, enemy stats/skills/spawns, movement physics, saves and network protocol are unchanged. Prior V275/V276/V277 animation assets and Frostbound snow/ice classification remain byte-identical. Only new enemy drawings/adapter routes and release/export/recovery metadata change. All43 original sheets, correction prompts/rejected originals where applicable, before references and the user's style reference are in tools/release278. Built-in imagegen was used.

## Restore and test

Extract ALL numbered V278 Editable source ZIP parts into the SAME parent. They form a standalone complete source tree. Open Crossroads_Realms_Beyond/project.godot with Godot4.5.1 and allow imports. The final live recovery registry identifies the exact successfully saved parts. Source chunks are deliberately smaller to avoid the large-transfer failures seen in V277.

RecoveryDelta/Working_Recovery are PATCHES over ALL THREE complete V277 source parts (Part1A, Part1B, Part2). Extract those together first, then apply the delta. Do not delete required base parts while relying on a patch. Prefer final standalone V278 source when all its parts are available.

After import run:
`godot --headless --path Crossroads_Realms_Beyond --script res://qa/v278_motion_check.gd`
Run retained V277/V276/V275 QA, then play all five realms in solo/co-op at normal gameplay scale: walking/stopping/attacks, long limbs and gear placement, Quarantine hound/minibosses, all additional Marsh/Silverfall encounters, Latch Hound summons, all four Neon boss shells and Fork Runner summons. Check shared Amber Hornet and all previous realms for visual regressions. The supplied native test has not been executed in this workspace.

The Web candidate preserves the verified V277 engine/autoload setup and PCK entries, updates changed raw scripts/assets and removes stale changed-script remaps. Server Update follows the existing source-server workflow. Preserve environment secrets and use the established server-before-Web process only after testing. Nothing was published.

## Continuity safeguards

Read current DEVELOPMENT_RECOVERY_HUB.md (libfile_bab654b363c4819198a9eb0d0b09ff78) on every resumption; it owns exact saved IDs, sizes, hashes and dependencies. Archive snapshots can predate final saves. Keep latest complete source plus V277 rollback, all still-required older base/patch/part dependencies, handoffs/style/prompt notes and original art. Protect active SUBVEIL Site/source and latest Windows package. Never delete automatically. Save compact checkpoints at meaningful milestones and before long generation/export work. Library listed-file usage is estimated, not exact billed quota; warn at16,000,000,000 bytes for the conservative20GB budget and do not claim full usage is below80% without a complete meter.
