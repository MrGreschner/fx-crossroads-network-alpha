# Deploy v100

## Render

**No changes required** for an existing protocol-26 service. All room_service files are unchanged from v99. Leave npm install, node server.mjs and the current server URL as they are.

## itch.io browser edition

1. Extract the editable source ZIP into a fresh folder. Open FX_Crossroads/project.godot in Godot 4.5.1 and let imports finish.
2. Export the Web preset with matching 4.5.1 templates to a fresh folder, using index.html as the entry point. Keep thread support disabled.
3. ZIP the exported files with index.html at the ZIP root. Replace the playable HTML5 upload on itch.io. Keep the existing mobile/fullscreen settings.
4. Reload the affected school PC. Main menu → Options → School performance ON; choose 30 FPS for the first test. Walk through the plaza and forest, then play one busy match on two devices. Keep the previous playable upload as a rollback.
5. If lag remains, download the diagnostic report from Options while it is slow. That report now includes CPU timing and rendering counters.

## Downloadable Windows edition

The archive is source, **not a playable Windows ZIP**. Use Project → Export → Windows Desktop, or tools/build_windows.ps1 (see WINDOWS_BUILD_GUIDE.md). Install matching Godot export templates first. The build script now names outputs v100. Upload the resulting Windows ZIP as a separate downloadable itch.io file, alongside the browser edition.

Players extract the Windows ZIP and run its EXE, with the accompanying PCK kept beside it. Internet access to the existing room service is still needed for multiplayer. Export/import the player's profile to transfer progress between browser and desktop. Confirm the school allows running downloaded executables.

No deployment has been performed automatically.
