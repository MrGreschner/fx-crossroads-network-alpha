# V375 — Lockjaw, Nutcracker and Finch Frost combat corrections

This is a complete replacement release based on V374. It retains the earned-only ownership schema/EPOCH 4 and individual champion opponents. There is no new ownership reset and no database schema migration.

## Lockjaw

- Snap now visibly opens and closes his approved bite poses, with a directional jaw snap and a fading arc showing its real reach. Front-facing anatomy, equipment, sprite scale and colours remain intact.
- A successful Clamp holds his closed-grip pose, stops walk cycling, raises his body slightly and draws a jaw clasp, attachment link, lock icon and local remaining-time/release cue. The pose/effect follows a moving target and is replicated to multiplayer clients.
- Attached Lockjaw cannot use Primary or Special. This is enforced in solo controls, held attack initiation, multiplayer requests, the authoritative attack path and shared casting. Secondary remains usable to release during cooldown.
- Existing six-second maximum, 8 damage/sec, 15% damage reduction, damage break threshold (40% of HP at attachment), anti-repeat protection and manual release remain. Dodging does not break Clamp.

## Nutcracker

- Fixed held Secondary repeatedly re-triggering and immediately cancelling Stand Fast. It now toggles only on separate presses in solo/training and arcade/network controls, including mobile action presses.
- Stand Fast lasts 4.5 seconds unless cancelled by a new Secondary press. Its planted pose, footprint marks, remaining-time label and local extended-reach guide make the state visible. Spear Jab uses its attack pose during thrust and returns to the stance afterwards.
- Primary works while braced: 25% damage increase and 40% extra reach (112 to 156.8 px). Existing 25% damage reduction, 48% movement speed, slower turn speed and 11-second cooldown remain.

## Finch Frost

- Cold now slows progressively from normal speed towards 40% speed as Chill approaches 100. A first 35-Chill spear gives 21% slow; two give 42% slow. The progress ring and percent label show accumulated Chill.
- All three existing ice attacks feed the same Chill state. At 100 Chill, the equipped Deep Winter passive freezes enemies; existing short boss/PvP freeze times, five-second refreeze protection after thaw and Chill decay remain.
- Actual NPC displacement and authoritative 60 Hz multiplayer movement both use this multiplier. Cold state remains in snapshots.

## Verification

Godot 4.7.2 local tests passed: real solo Snap/Clamp hits; held pose phases; blocked Primary/Special/direct casts while attached; moving-target follow; manual release during cooldown; damage-threshold release; all six damage ticks and six-second expiry. Actual held-button input through multiple frames no longer cancels Nutcracker stance; its extended-range boosted jab, full duration and second-press cancellation work. Cold decreases actual enemy movement, freezes and recovers with immunity, and all three Frost attacks add Chill. Real dedicated network arena tests cover blocked attack packets, replicated latch pose, Nutcracker braced hit/cancel, progressive movement slowdown and cold snapshots. Existing ownership migration and all 28 champion combat simulations passed. Native rendered bite/latch, brace/jab and Chill cues were reviewed. Existing resource cleanup warnings occur at process shutdown; no script/runtime errors in the final checks. Live browser/mobile/Render deployment and human gameplay balance remain to be tested after upload.

## Complete packages and deployment

- Crossroads_v375_Web.zip: complete browser build. Extract all contents for the web host. Large game data is stored in ordinary parts of at most 32 MiB, assembled automatically by the existing loader.
- Crossroads_v375_Server_Project.zip: complete server repository source/artwork, project.godot, Dockerfile.network and network_service. Extract and copy the CONTENTS into the existing GitHub Desktop repository, replacing matching files. Preserve .git, existing Render configuration/environment/database. Commit and push. Use Dockerfile.network on Render. Do not commit this ZIP archive or an exported .pck.
- Crossroads_v375_Editable.zip: complete Godot source/artwork. Extract and open Crossroads_Realms_Beyond/project.godot.

Update BOTH web and Render server so the authoritative combat and visible cues agree. No separate scripts or prior release downloads are required. Every individual file inside the Web and Server packages is under 100 MB; the ZIP downloads themselves are larger and are not intended to be committed to GitHub. Archive checks, full source matching, game-data hashes and packaged-script loading are validated during packaging. Keep V374 as rollback.
