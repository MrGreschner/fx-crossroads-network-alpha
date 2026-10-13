# v115 — Shared-computer welcome and Game Dev desk

## Tutorial on each launch
Fresh page loads/process launches offer First Steps regardless of saved tutorial, run count or journey skip history. The familiar first-nine hero picker and Skip introduction remain. The offer is handled once per launch, not each town visit or main-menu return. Upload/download profile navigation cannot silently consume the offer; it appears after the player returns to town. New/Clear explicitly starts a new player and offers it again. Training Guide still supports manual replay. Opening another tab is a separate launch.

This does not identify who is sitting at a shared computer or erase existing progress. Continue to teach students to upload their own profile and use New/Clear when leaving a shared PC. No profiles are automatically cleared by the welcome screen.

## Game Dev testing desk
Tell Elder Ram `gameDev`, then enter `R4ms`. The existing temporary unlocks and gold screen border remain. A DEV DESK button opens:
- Restore health and Reset cooldowns for solo experiments.
- Training / all attacks ready, from town, at level 10.
- A short custom DEV DEMO presentation caption for recording/projector demonstrations.
- Direct access to the student playtest notebook.
- Back to game and Exit Dev / restore profile.

The desk suppresses gameplay input while it is open; Escape closes it. Solo gameplay waits while the desk is open, but online matches continue. Health/cooldown/training experiment actions are unavailable in multiplayer scenes. Captions are local presentation overlays, not messages to other players. Closing the desk restores the previous menu/input state. These controls are temporary and do not save to a profile. Existing Game Dev restrictions still block progression, score/achievement awards, profile saves/downloads/imports. Reports are separate and may be exported. Exit or refresh removes the temporary mode and its tools/caption.

## Animated multiplayer identity
Game Dev heroes have gold feather-like animated wings, a halo and three orbiting sparks. Multiplayer nameplates show GAME DEV; party names have a DEV prefix. Both hosting and joining transmit the flag through existing hero/lobby metadata and reliable player metadata. Departing players and reset connections clear stored cosmetics. Normal player names/profiles remain unchanged. Enemy Cat invisibility hides the whole player ornament/nameplate with the hero. Dead players do not display wings in match play.

The marker is cosmetic, not verified administrator access. It never supplies combat authority. Animations use a fixed number of vector primitives, not particle emitters or extra per-frame network events. All players should use v115 for the new marker to be shown consistently.

## Checks
Godot 4.5.1 targeted tests pass for saved-veteran welcome, skip/new-launch behaviour, profile-action welcome preservation, input blocking/restoration, solo test actions, level10 training, presentation caption, Game Dev save guard, host/guest lobby and snapshot metadata, multiplayer experiment refusal, marker clearing and departed-player cleanup. v112/v113/v114 regression checks pass. Rendered tutorial, testing desk, caption, town wings, party lobby and simulated multiplayer nameplates. ZIP CRC, extraction and all v114 source filenames verified.

Physical phones, school browsers and a live multi-computer session were not available here. Compiled Web/Windows exports are not included in this editable source archive. This update does not claim to eliminate browser WebGL context loss.

## Deploy
1. Extract the source ZIP into a fresh folder; open FX_Crossroads/project.godot.
2. Export Web again, ZIP the exported files with index.html at the root, and replace the itch.io browser build.
3. If offering the Download game button, rebuild and upload the Windows player ZIP using the included Windows build guide. The editable source ZIP is not the student Windows installer/player build.
4. No rooms.mjs, server.mjs, package.json, Render build/start command or settings changes are required.
5. Students should refresh into the new build. Check one real school phone and one two-computer party before announcing the release.
