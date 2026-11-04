# Crossroads V277 — animated enemies for five more realms

Candidate scope: Moonveil Masquerade, Petalbrook Canopy, The Clockwork Orchard, Crossbell Middle School and Orbital Breach.26 new four-pose sets plus three already-upgraded V276 Firstbell sets reused at Crossbell. The roster file lists every enemy/boss appearance and shared identity. No realm or enemy has been silently replaced with a generic design.

Each new set has idle, movementA, movementB and attack. Walkers alternate planted/lifted feet plus counter-swinging arms, paws, sleeves, capes, ears, tails or articulated mechanical parts. Hourglass Hart keeps its quadruped gait. Spiders/beetles use jointed legs. Culture Blob flows through complementary lobes. Pendulum Moth uses wings and a moving pendant. Orbital drones, mines, Void Seeker and Signal Core remain floating objects with rotor/strut, spoke, tendril or panel motion. No humanoid limbs are added to those objects. Floating enemies also animate while stationary.

The visual target is the existing simple Bramble/Archer/Imp style: coarse pixel clusters, matte midtones, restrained palette and selective coloured edges. Identities, equipment side, original visible idle height and fixed frontal view are preserved. No directional body frames, mirroring or rotating the body to aim. Attacks take priority over locomotion; projectile aiming stays independent. Grounded animation uses existing traveled-distance samples and stops when the enemy stops, without synthetic whole-body walking bounce. School overlays retain their existing step selection.

## Validation and practical limits

The included static validation report records the actual passed checks. It checks four distinct nonempty frames, binary alpha/no halo, frame margins, original visible height, motion above the feet, roster coverage, drawing routes, attack priority and preservation of all old files except the explicit presentation/release/hub allowlist. Changed/new GDScripts parse. Source/Web/Server changed runtime bytes and PCK entry hashes are compared. ZIP CRCs and every complete-source member are verified when packaging. The GIF and interactive HTML use the actual candidate atlas, but are artwork previews rather than live gameplay captures.

Native Godot/browser runtime playtests have NOT been run in this workspace: those executables are unavailable. This is a saved-source candidate awaiting import/runtime tests. V276 is its complete saved candidate baseline/rollback; V274 remains the last previously runtime-validated release. No deployment, deletion or unsupported FPS/co-op/database claim.

All hero artwork, prior V275/V276 sets, scenery, Frostbound snow/ice classification, existing scenes/content, collision, movement physics, combat/stats, spawns, saves and network protocol are unchanged. Only the new enemy atlas/drawing adapter and release/export/hub notes change. Original26 imagegen sheets, exact prompts, before references and the user style image are included in tools/release277. Built-in imagegen was used for identity-preserving artwork edits.

## Restore and test

Complete source: extract BOTH V277 Editable Part1/Part2 ZIPs into the SAME parent, then open Crossroads_Realms_Beyond/project.godot in Godot4.5.1 and allow imports. These complete parts are standalone.

RecoveryDelta/Working_Recovery are patches over BOTH complete V276 Editable parts. Extract V276 Part1+Part2 first, then apply the delta. A working checkpoint may be partial: prefer the final successful-save registry in the live recovery hub. Never infer a finished/saved release from chat claims.

After editor import run:
`godot --headless --path Crossroads_Realms_Beyond --script res://qa/v277_motion_check.gd`
Also run retained V276/V275 QA, then play all five realms in solo/co-op. Check walking/stopping/attacking at normal game size; equipment side; wings/pendants/rotors/tendrils; Clockwork charges/summons; both Crossbell bosses and Culture Blob summons; all shared Crossbell enemies; Orbital Signal Core and projectile timing. The supplied native test has not been executed here.

The Web candidate reuses the verified V276 engine/PCK base, removes stale compiled remaps for changed scripts and includes the new raw atlas. Server Update follows the existing source-server workflow. Preserve secrets/environment variables and follow the established server-before-Web process only after local testing. Nothing was published.

## Continuity

Read current DEVELOPMENT_RECOVERY_HUB.md (libfile_bab654b363c4819198a9eb0d0b09ff78) at every resumption. It owns exact successfully-saved IDs, sizes, hashes and dependencies; snapshots inside source may predate final saves. Keep V277 complete source plus V276 rollback and all still-required older dependencies, all handoff/style/prompt notes and original art, active SUBVEIL Site/source and latest Windows package. Never delete automatically. Warn at16,000,000,000 known listed bytes for the conservative20GB budget; listed metadata is only an estimate, not exact billed quota. Save compact checkpoints at meaningful milestones and before long generation/export work.
