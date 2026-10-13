# Deploy v103

## 1. Render
Replace the four files in the GitHub directory Render builds from with the matching files from this archive's **room_service** folder:
- rooms.mjs
- server.mjs
- package.json
- package-lock.json

If the repository keeps tests, copy all room_service/*.test.mjs files too; package.json references the new v103 test.

Commit and allow auto-deploy, or choose **Manual Deploy → Deploy latest commit**.
Keep **Build Command: npm install** and **Start Command: node server.mjs**. Keep your existing root directory, service URL, PORT and environment settings. Use Node 22 or later. No new server, database, paid service or environment variable is needed. Health/server information now reports **version 28**.

These server changes are necessary for changing seats/bots/mode/realm while a party stays in the lobby. Deploy Render before uploading the new playable game.

## 2. itch.io
1. Extract this archive into a fresh folder. Open **FX_Crossroads/project.godot** with Godot 4.5.1 and matching export templates.
2. Export Web into an empty folder as **index.html**, keeping threads disabled and the included HTML head diagnostics settings.
3. ZIP the exported files with index.html at the ZIP root. Replace the playable HTML5 upload on itch.io. **Do not upload this editable source ZIP as the playable browser build.**
4. Close old game tabs and reload. Old protocol-27 rooms cannot join protocol-28 rooms. Portable profile progress remains supported.
5. Export Windows separately with matching templates if you also publish the downloadable build.

## 3. Short school-PC check
- In Options, run the on-screen diagnostic check on a smooth PC and a laggy PC. Compare FPS cap, frame delays, browser and graphics details. Try School performance ON / 30 FPS on weaker devices.
- Walk through Honeyglass, Folded Coast and Moonveil; confirm paths, props and new enemy warnings are visible.
- Host an arena with a second person. Change seats, add/remove bots, change map and hero, then start. Check trees do not trap spawn/respawn locations.
- Test Descent level-11 choices and health gems. For teacher testing, check floors 5, 10 and 30 are single-boss encounters; teacher mode does not earn badges.
- Recheck disconnect/rejoin and town aura suppression.

No automatic deployment or compiled Web/Windows export is included. These changes reduce avoidable work; they do not guarantee prevention of browser GPU context loss on every school machine.
