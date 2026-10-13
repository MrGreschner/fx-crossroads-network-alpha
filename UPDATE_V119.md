# v119 — Welcoming menus and daily adventures

## Changes

- Continue enters town without forcing the hero tutorial. New Game opens a welcoming confirmation with a green Start • enter tutorial button, then clears the local profile and opens First Steps. The reset warning and backup guidance remain; Skip remains available. Upload/Download still work in town.
- The training guide moves 105 pixels right and 15 down, into a more detailed stone-and-timber shelter with windows, lamps, entrance steps and equipment rack. Hero Book stays at the left. Watering beds and nearby resident/flower decorations are moved onto a compact lawn garden west of the training entrance, clear of paths and barracks. Interaction positions move with the beds.
- Main menu, Adventures and Profile show today’s challenge: one task from an authored, deterministically shuffled list of 50. There are 24 solo/co-op realm trips, 12 featured-hero clears and 14 Descent/Defence milestones. Survival targets are cleared floors/waves, not merely reached/spawned stages.
- Completing a task earns the animated Daystar Crest until local midnight. It has no combat benefit. Reward state travels with the profile and appears to other players through existing reliable cosmetic metadata. No server changes are needed. Game Dev, tutorial, training and spectators do not earn it. The device’s local date drives the offline calendar.
- Elder Ram’s chat box and Ask button are first, with all quick topics below. There is no Something else subpage. New daily challenge, charge controls and shared-computer advice, plus a few jokes, are included. gameDev followed by R4ms still enters temporary testing mode.
- FX CROSSROADS title intro lasts 3.8 seconds with a gentle final fade. A ram and Bramble animate a short encounter underneath it using existing sprite assets.

## Checks

Tests cover all 50 tasks and IDs, deterministic nonrepeating cycles, real solo victory hooks, hero/team requirements, survival target completion, profile export/import validation, midnight expiry, Game Dev exclusion, reward cosmetic metadata, Continue without tutorial, actual New Game reset/reload into First Steps, and direct Elder chat/password prompts. Existing tutorial-death and charged-attack regressions are rerun. Rendered main menu, confirmation, Elder chat, training yard, lawn beds, daily card and intro are inspected. ZIP CRC and full extraction are verified.

Local automation cannot reproduce physical phone touch or the school’s live network/GPU conditions. Please smoke-test one fresh New Game, one Continue, tutorial death, a charged cast, and a two-player room before advertising.

## Deploy

1. Stop Godot and extract this editable ZIP into a fresh folder. Open FX_Crossroads/project.godot.
2. Test with F5, then re-export Web and replace the complete itch.io Web upload.
3. Rebuild and replace the Windows download if distributing it.
4. Refresh clients so everyone uses v119. No Render file, setting or command changes are required.

All 80 heroes, v118 tutorial death safeguards and earlier features remain. This ZIP contains source, not a compiled Web or Windows game.
