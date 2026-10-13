# Deploy v132

## Render — redeploy required for Partner Up
1. Replace your repository's `rooms.mjs`, `server.mjs`, `package.json` and `package-lock.json` with the copies from `FX_Crossroads/room_service/` in this ZIP. Also copy the included service test files if you run `npm test` in your repository.
2. Commit and push. In Render, deploy the latest commit (or wait for your automatic deployment).
3. Keep your current repository root-directory setting. Build command: `npm install`. Start command: `node server.mjs`. Use Node 22 or newer. Keep the current service URL and environment variables; no new database or secrets are needed.
4. Wait for **Live**. The gameplay protocol remains 30; the server now advertises the additional `studio_partner` capability. Older room services produce an explanatory Partner Up message instead of pretending the feature is connected.

## Godot / itch.io
1. Extract the editable ZIP and open `FX_Crossroads/project.godot` in Godot 4.5.1, with matching export templates.
2. Export Web into an empty folder. ZIP the exported files with `index.html` at the ZIP root, then replace the browser-playable file on itch.io. This editable ZIP is not the playable Web export.
3. Rebuild and replace your downloadable Windows ZIP too, if offered.
4. Reload both test devices. Create a Partner Up code, join from the second device, change artwork or damage, pass the pencil, and export a shared creation from each device.
5. Check Playtest's blue border, protected progress, Profile's cosmetic picker and one multiplayer cosmetic. Then test an ordinary multiplayer match.

Web/Windows export templates are not installed in this workspace. These exports and a final school-browser/phone check must be done on your machine. No hosting account was changed automatically.
