# Deploy v89 to Render and itch.io

This ZIP is the editable Godot source, not the playable browser ZIP. Keep a backup of the currently published build and download your player profile before replacing it.

## Render — update the existing room service

1. Unzip this release. In the GitHub repository already connected to Render, replace **rooms.mjs**, **server.mjs**, **package.json** and **package-lock.json** with the files from **FX_Crossroads/room_service/**. Preserve the existing repository layout. The test files are optional for hosting; copy them too if you want to run the included tests there.
2. Keep your existing Node service and **Branch: main**. **Root Directory** stays blank if those four files are at the repository root. If you placed them inside room_service, set it to **room_service**.
3. **Build Command: npm install**. **Start Command: node server.mjs**. Keep the existing service URL and environment variables. Render supplies PORT; no new variable or separate service is needed for this update. Use Node 22 or newer, as declared in package.json.
4. Commit/push the changed files. Let auto-deploy run or choose **Manual Deploy → Deploy latest commit**. Check the service log for **FX Crossroads room service v23 ready**. Opening its HTTPS address should return JSON containing **"version":23**.

## Godot and itch.io — fresh playable build

1. Open the extracted **project.godot** in Godot 4.5.1, the version used for this release's checks. Install matching export templates. Allow the initial asset import to finish.
2. Export the Web preset to a new empty folder, with **index.html** as its entry point. ZIP the exported files themselves so **index.html is at the ZIP root**. Do not upload this editable-source archive as the HTML game.
3. On the existing itch.io edit page, replace the playable Web ZIP with that new export. Retain the existing HTML5/mobile/fullscreen settings. Save the page. Export Windows separately if you also offer the downloadable edition; tools/build_windows.ps1 and the build workflow are updated to v89.
4. Ask every player to reload so they use v89. Versions are isolated in room browsing; mixing cached builds does not make a valid new v89 room. Test one solo arena with bots and one real two-device multiplayer match before students join.

## Short release check

- Select heroes 66 and 67; check four ability cards, then mastery choices.
- Test a held attack and orientation change on a phone. Check Menu and sound access.
- In arena choose Play Solo with three bots; verify the large countdown.
- In a two-device match verify selected stance attacks, a reconnect and returned lobby.
- Plant, clear an adventure, harvest, export/import a profile and confirm gardening progress.

Do not reset profiles just to install the update. This package has not been deployed to your accounts. A fresh browser export still uses WebGL2; this update cannot guarantee that school-managed browser graphics will never lose their context. Keep the Windows edition and diagnostic download available.
