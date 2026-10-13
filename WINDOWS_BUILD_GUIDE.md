# Publish the Windows edition — v122

This editable project ZIP is source code, not a playable Windows game. Build the playable ZIP below before offering it to students. The Windows build bypasses Chrome/WebGL2, but still requires working graphics drivers. It is not a guaranteed fix for every crash.

## Recommended: build on your Windows computer

1. Download and extract `FX_Crossroads_expanded_editable_v122.zip` into a fresh folder.
2. Open the extracted `FX_Crossroads` folder.
3. Double-click **BUILD_WINDOWS.cmd**. You do not need to edit any game files.
4. Keep the window open. The first run downloads Godot **4.5.1**, matching export templates and the official native WebRTC extension **1.2.2**. It imports the project, checks that native WebRTC can create a peer/data channel, and exports the Windows game. This can take several minutes. The window must finish with **Build complete**.
5. Find **exports/FX_Crossroads_Windows_v122.zip**. This is the playable Windows ZIP to upload, NOT the editable project ZIP.
6. Extract that Windows ZIP yourself. Open **FX_Crossroads.exe** and test one solo realm, Windows-to-Windows multiplayer, and Windows-to-browser multiplayer. Players do not need Godot to play.

If the build fails, keep the error text. Do not publish a partial EXE. School policies may block PowerShell, GitHub downloads or unsigned games; ask IT to approve this specific build/game. No administrator account is needed by the builder. Do not disable school security controls.

### Also build the matching browser update

In the extracted `FX_Crossroads` folder, open PowerShell and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .	oolsuild_windows.ps1 -AlsoWeb
```

This creates both **exports/FX_Crossroads_Windows_v122.zip** and **exports/FX_Crossroads_Web_v122.zip**. The builder handles templates and native networking automatically. Alternatively export the Web preset in Godot as usual. Use matching v122 builds for browser and Windows players.

## Upload to your existing itch.io page

1. Open your FX Crossroads itch.io page and choose **Edit game**.
2. Keep the game type **HTML Game**. Keep the browser build available.
3. In **Uploads**, replace the existing browser upload with **FX_Crossroads_Web_v122.zip**. Mark this file as **played in the browser**.
4. Add a separate upload: **FX_Crossroads_Windows_v122.zip**. Mark its platform **Windows**. Do NOT mark this ZIP as played in the browser. Give it a clear display name such as **FX Crossroads — Windows v122 (recommended for school PCs)**. Ensure this download is available free to students.
5. Save the page. Check the public page while logged out: students should see a Windows download as well as Run game.
6. Open the updated browser game. **Main menu → Download game → Open itch.io downloads** opens `https://fxcts.itch.io/fx-crossroads#download`. The button goes to the page's downloads, not an upload ID that would break every update. If there is no download section yet, publish the Windows ZIP first. If your itch.io page URL ever changes, update `GAME_DOWNLOAD_URL` in `scripts/session_menu.gd`.

No Render settings or room-service code changes are needed for v122. The Windows edition uses the same existing Render room service. Internet/network access is still required for online multiplayer.

## What students do

1. Click **Download game** on the main menu, then **Open itch.io downloads**.
2. Download the Windows ZIP; extract the WHOLE ZIP.
3. Open **FX_Crossroads.exe** inside the extracted folder. Keep its PCK and DLL folders beside it.
4. To move existing progress: in the browser, return to town and **Download profile**; in the Windows game's main menu, **Upload profile**. Browser and Windows saves are separate. Game Dev mode cannot export profiles.
5. Once the Windows game is working and the profile is transferred, close the browser game tab so both games are not rendering at once.

This Windows download is not a phone app. Mobile players continue using the browser edition. If school computers block the executable, IT approval is needed before students can run it.

## Alternative: GitHub Actions

If you cannot build locally, upload this whole project (not just the room-service files) to an appropriate game-source repository, with `.github/workflows/build-windows.yml` at the repository root. Run **Actions → Build FX Crossroads Windows → Run workflow**. Download the **FX-Crossroads-Windows-v122** artifact when it succeeds, extract the outer artifact ZIP, and upload the Windows player ZIP inside to itch.io. The workflow exports Windows only; export Web separately. Do not replace your Render room-service repository layout solely to enable this workflow.

## Verification limits

The main-menu panels were loaded and visually checked in Godot 4.5.1; build filenames and artifact paths were checked. A compiled Windows executable cannot be built/run in this Linux environment without the downloadable Windows templates/native extension. The included Windows script is the build route on your PC; native multiplayer still needs testing on your school network before classroom rollout.

Official references:
- https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_windows.html
- https://github.com/godotengine/webrtc-native/releases
- https://itch.io/docs/creators/html5
