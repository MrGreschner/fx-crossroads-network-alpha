# Crossroads V283 — Shadow Hunters and 24-hour Attunement replay

Reconstructible SOURCE CANDIDATE. Source, static artwork, timer-expression and cloud-format checks passed; real Godot/native/browser playtesting is pending. Nothing deployed or deleted.

## Nine Veilbound hunters
The nine Between pursuers now use dark hooded, faceless shadow designs in matte coarse pixel art, with readable slate/plum/teal edges. Their existing names, equipment motifs, combat kits, stats, attack telegraphs, spawning/escalation, safe entrance, retreat and return timers are retained. Heroes, ordinary enemies, realm scenery and merchant update are retained.

Five walkers: Shear of the Seam, Fracture Witness, Threshold Hound, Maw of the Interval, Last Threshold. Four hoverers: The Spindle, Hollow Mourner, The Unwritten, Null Regent. Every hunter has idle, movementA, movementB and attack:36distinct transparent80×80frames in one320×720atlas. All poses face forward without turning or mirroring. Walkers alternate feet/paws, opposite arms and robe folds; hoverers change separate ribbon/sleeve/page shapes and use a small1.6pixel hover offset. Neutral hover cloth also cycles at rest. Four-armed Warden and low hound preserve distinct silhouettes.

The shared existing movement sampler uses world-distance poses, survives replaced co-op dictionaries and ignores teleports. Hunter-only strides are20(hound),28(heavy Maw/Warden)and24(other hunters), improving footstep readability at their existing speeds. Existing non-hunter strides are unchanged. Solo loader and shared install use the new atlas; explicit solo/co-op drawing prevents the old SVG art returning after a spawn. Old source SVGs remain preserved as originals.

Built-in image generation produced three original sheets. Exact prompts, originals, normalization scripts, baseline and validation are in tools/release283. assets/hunters283 contains runtime atlas and frame manifest. PNG/GIF previews show actual normalized artwork and animation frames, not Godot gameplay captures. The GIF demonstrates movement; the PNG includes the attack poses too.

## Attunement replay
The user's “24s” was interpreted explicitly as24HOURS. This is a rolling86,400-second real-time cooldown from a successful solo trial extraction with all six Crossing Seals, including the first successful attunement. It is not a calendar-day/midnight reset. Failed, forfeited, defeated or incomplete attempts never start or extend it. Normal Between solo/co-op and Overcharged Realms remain available under their existing unlock rules.

waylight.attunement_completed_at is saved as a Unix UTC whole-second timestamp inside the existing profile/cloud save. It is optional on old profiles and validated when present. Old attuned saves without a known completion time remain ready until their next success; no invented retroactive lock. Duplicate-settlement protection remains. Game Dev/practice retains its existing non-persistent behavior.

Both the entry/payment gate and UI enforce access. The UI shows a live HH:MM:SS countdown and re-enables the button at expiry; the first attunement permanent unlock and existing bonus remain intact. Interrupted valid runs remain resumable. Timing uses the game's existing profile/system clock; this is not a new server-side anti-cheat attestation. Cloud profile revisions/conflict behavior is unchanged.

## Restore source
Extract ALL FOUR complete V278 Editable parts into ONE parent, then overlay FINAL Crossroads_v283_RecoveryDelta.zip into the SAME parent. This creates Crossroads_Realms_Beyond/project.godot. The delta is cumulative and includesV279,V280,V281,V282,V283. It is a PATCH, not standalone; do not overlay older deltas afterward. Use Godot4.5.1.

| Required base | Library ID |
|---|---|
| V278Part1 | libfile_6ffd51a687308191b621c32e0e226f82 |
| V278Part2 | libfile_cd7f3e6aa12881918c5d25cfd49f9af5 |
| V278Part3 | libfile_b28256d1ee74819182d8670024976663 |
| V278Part4 | libfile_ee6d644f25888191ae456d97e42ab9e6 |

Rollback is final V282delta libfile_160daf67e1488191b8a78b4d5def7cf8 plus those same bases. Keep V282Web/Server as incremental build inputs. ExactV281delta+fourV278bases remain permanently required by Crossroads_Legacy_Source_History.zip; do not delete them afterV283. Preserve V280/V274 and all protected dependencies/notes/original art. SUBVEIL Site/source/latestWindows untouched. EarlierV283WorkingRecovery is a checkpoint OVERV282, not the final cumulative source.

## Validation and remaining tests
Full V282baseline contains20,321files; changes are limited to scoped hunter presentation/movement, attunement progression/UI, release settings and the recovery hub snapshot. All original assets/content/scenes and every hunter AI/combat/snapshot method remain byte-identical. Eight modified/new GDScripts parse. All36distinct registered crops and upper/lower movement differences checked. Seven boundary tests execute the actual pure timer source expression with matching integer semantics (not Godot runtime execution). The real cloud validator accepts timestamp JSON roundtrips/old profiles and rejects nonfinite numbers. Eleven changed runtime resources match source/WebPCK/Server byte-for-byte. Final archive CRCs and four-base-plus-cumulative-delta source reconstruction are verified; see Integrity for hashes and counts.

Web/Server packages are incremental candidates from saved V282, not fresh Godot exports. Godot executable is unavailable and its download attempt timed out; native import/boot, actual GDScript QA execution, solo/co-op/browser playthrough, live server/DB and hardware FPS were NOTRUN. After importing in Godot4.5.1, run qa/v283_hunters_attunement.gd and retained pursuer/Between/attunement QA. Verify all9hunters in solo and co-op, movement versus rest, attacks, remote snapshots, arrival/dodge/retreat, readable silhouettes and HP bars. Test fresh first success, failed/incomplete/forfeit attempts, locked direct entry, countdown expiry, menu reopen/restart/cloud save restore, normal Between/Overcharge access and an interrupted trial resume. Test actual school hardware performance before deployment.

Next environment remains Lantern Marsh, only when requested. This update does not advance the environment queue. The canonical live DEVELOPMENT_RECOVERY_HUB.md supersedes pre-final registry snapshots inside archives.
