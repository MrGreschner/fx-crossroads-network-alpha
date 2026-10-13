# Deploy v137

**No Render or room-service changes are required.** Music uses the existing peer channel; Render does not host recordings.

1. Extract this complete source ZIP into a new folder. Open its `FX_Crossroads/project.godot` in Godot 4.5.1 and let initial imports finish. Avoid opening the old v136 folder or copying only selected scripts.
2. Run locally. Confirm town startup, Music Studio and the Media shortcut guide.
3. With matching export templates installed, export Web into an empty folder. ZIP the exported files with `index.html` at the root. Replace the browser-playable itch.io upload. The editable project ZIP itself is not the Web upload.
4. Re-export Windows and replace the downloadable game ZIP.
5. On a school browser, upload a short BandLab WAV effect and a music prototype. Listen, assign to a realm, test, mute, then download/upload the player ZIP.
6. Test a two-device multiplayer room with a small MP3 soundtrack assigned by the host. Allow transfer time and check mute on each device. Normal gameplay traffic keeps priority over audio transfer.

Editable source startup and native UI were verified here. Export templates are not installed in this workspace, so actual browser/Windows exports and classroom peer connections still need the checks above on your devices.

The reported v136 error was a missing imported SVG preload. v137 stores those SVG sources in `content/source-art.json` and decodes them once into a texture cache, bypassing image-import remaps in both source and exported builds. After editing original SVG artwork, regenerate that JSON with `tools/refresh_source_art.py` before exporting.
