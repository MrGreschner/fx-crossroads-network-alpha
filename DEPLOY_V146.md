# Deploy v146

1. Download/back up current player profiles before updating.
2. Extract this **editable project** ZIP into a fresh folder. Open `FX_Crossroads/project.godot` in **Godot 4.5.1**. Let asset import finish; run the project once.
3. Export **Web** using the supplied preset. ZIP the exported files with `index.html` at the ZIP root, and replace the browser-playable itch.io upload. The editable source ZIP is not the playable web upload.
4. Export **Windows Desktop** from the same project and replace the Windows download. `tools/build_windows.ps1` names its outputs v146.
5. Test on a school computer: expanded Studio entrance; alternate hero form; one object/PNG export; a realm with wall and water tiles; reachable exit; a placed enemy; profile ZIP export/import; Student submission and Teacher review; one multiplayer match with everyone on v146.

**Render:** no room-service code changes in this update. If your service already runs the v144-or-later `room_service` files, no redeploy is needed. If still behind, replace `rooms.mjs`, `server.mjs` and `package.json` from this project and redeploy once. Keep the same URL/root directory. Build: `npm install`. Start: `npm start`. Node >=22. No database or new environment variables.

Object/Realm creations are shared as local project files and played in Studio tests; they do not add new server-hosted multiplayer realm types.
