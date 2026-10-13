# Deploy v133

## Render
The mine needs no server and introduces no room-service changes. If Render is already running the v132 Partner Up service (protocol 30 with studio_partner), leave it unchanged.

If you have not deployed v132 yet, update the repository's `rooms.mjs`, `server.mjs`, `package.json` and `package-lock.json` using this ZIP's `room_service/` copies. Keep your existing root-directory setting. Build command: `npm install`. Start command: `node server.mjs`. Node 22 or newer. Deploy the latest commit and wait for Live. This is necessary for Partner Up, not idle mining. There are no new database, secret or environment-variable requirements.

## Godot and itch.io
1. Extract this editable source ZIP; open `FX_Crossroads/project.godot` in Godot 4.5.1 with matching export templates.
2. Test the town mine entrance. Commission, hire, collect and queue an upgrade. Leave and return; confirm production and the timer progress.
3. Download a profile, upload it, and confirm the mine is retained. Use Game Dev to preview the deep mine and verify its changes disappear after refreshing or exiting.
4. Export Web into an empty folder. ZIP every exported file with `index.html` at the ZIP root. Replace the browser-playable upload on itch.io. This editable source ZIP is not the Web export.
5. Rebuild the downloadable Windows edition if offered. Replace that ZIP too.
6. Reload your test devices, check touch scrolling and a normal multiplayer match, then distribute the update.

Web and Windows export templates are not installed in this workspace. You still need to build the playable exports on your machine and check school browsers/phones. Keep a backup of existing profiles before replacing the live upload.
