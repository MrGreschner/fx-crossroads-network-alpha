# Deploy v95

This archive is the editable Godot project. It must be exported before uploading the playable game to itch.io.

## Render

**No changes are needed for this update if your deployed service is already v26.** v95 uses the same room protocol and service files as your deployed v94 build.

Keep your existing service URL, branch and environment variables. The settings remain:

- Build command: `npm install`
- Start command: `node server.mjs`
- Root directory: blank when the service files are at your repository root; `room_service` when they are in that folder.

## Godot and itch.io

1. Extract the archive into a new folder. Open `FX_Crossroads/project.godot` in Godot 4.5.1 and let imports finish. Install matching export templates if needed.
2. Export the Web preset to a new empty folder with `index.html` as the entry point.
3. ZIP the exported files with `index.html` directly at the ZIP root. Replace the existing playable HTML5 upload on itch.io with this Web ZIP. Keep the current mobile/fullscreen settings and save.
4. Export Windows again if you offer the downloadable edition. `tools/build_windows.ps1` and the build workflow now label outputs v95.
5. Reload the page on every device. Keep the previous playable upload as a rollback copy.

Before students join, test favourite on/off and search by hero number, Options, a phone landscape rotation, a short solo Gate Defence run and an actual two-device multiplayer match. Download a diagnostic report if a browser freezes. Local tests do not replace that classroom hardware check.

The room server has not been redeployed by this update, and the editable source archive is not itself the playable browser or Windows build.
