# v108 — Archive repair and training improvements

The supplied local v107 ZIP was truncated: it had no ZIP central directory and could not be extracted. This replacement is built from the complete editable project, closed before publication, CRC checked, fully extracted into a temporary directory, and compared with the v106 archive's required payloads. All 74 heroes and the v107 PvP minion fix are included.

## Quick testing
- Character Hall: Test hero appears to the left of Story, beneath the selected hero's name. It starts that hero at level 10 in the Training Yard with all attacks unlocked.
- Training Yard: approach the open book pedestal and press E (or Interact on mobile) to choose another hero. Continue returns you to the same spot with the new hero.
- The guide is farther right beneath a shelter. Training labels use the game UI font. A rack displays a sword, shield, arrows and staffs; an ember bucket and frost staff add small animated details. Three overlapping trees were removed.

## Install and publish
1. Extract this ZIP into a NEW folder; open FX_Crossroads/project.godot in Godot.
2. Export the Web preset again. Upload the exported Web ZIP to replace itch.io's browser build. Do not upload this editable source ZIP as the browser game.
3. For the Windows download, run BUILD_WINDOWS.cmd and upload exports/FX_Crossroads_Windows_v108.zip as a separate Windows download. WINDOWS_BUILD_GUIDE.md contains the steps.
4. No Render redeployment or room-service settings changes are needed.

## Verification
Godot 4.5.1: training interaction regression test passed; v107 minion regression test passed. Character Hall and the training area were rendered and visually checked at 1280 x 720. Archive CRC and full extraction checks passed. Windows/Web exports and live network play were not run here.
