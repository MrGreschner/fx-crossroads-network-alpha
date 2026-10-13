# Deploy v91 to Render and itch.io

This ZIP is the editable Godot source, not the playable browser ZIP. Keep a backup of the currently published build and download your player profile before replacing it.

## Render — update the existing room service

1. Unzip this release. In the GitHub repository already connected to Render, replace **rooms.mjs**, **server.mjs**, **package.json** and **package-lock.json** with the files from **FX_Crossroads/room_service/**. Preserve the existing repository layout. The test files are optional for hosting; copy them too if you want to run the included tests there.
2. Keep your existing Node service and **Branch: main**. **Root Directory** stays blank if those four files are at the repository root. If you placed them inside room_service, set it to **room_service**.
3. **Build Command: npm install**. **Start Command: node server.mjs**. Keep the existing service URL and environment variables. Render supplies PORT; no new variable or separate service is needed for this update. Use Node 22 or newer, as declared in package.json.
4. Commit/push the changed files. Let auto-deploy run or choose **Manual Deploy → Deploy latest commit**. Check the service log for **FX Crossroads room service v25 ready**. Opening its HTTPS address should return JSON containing **"version":25**.

## Godot and itch.io — fresh playable build

1. Open the extracted **project.godot** in Godot 4.5.1, the version used for this release's checks. Install matching export templates. Allow the initial asset import to finish.
2. Export the Web preset to a new empty folder, with **index.html** as its entry point. ZIP the exported files themselves so **index.html is at the ZIP root**. Do not upload this editable-source archive as the HTML game.
3. On the existing itch.io edit page, replace the playable Web ZIP with that new export. Retain the existing HTML5/mobile/fullscreen settings. Save the page. Export Windows separately if you also offer the downloadable edition; tools/build_windows.ps1 and the build workflow are updated to v91.
4. Ask every player to reload so they use v91. Versions are isolated in room browsing; mixing cached builds does not make a valid new v91 room. Test one solo arena with bots and one real two-device multiplayer match before students join.

## Short release check

- Check Merrymask String Scissors, Dust Marshal pistol travel, Crumb Cook artwork and the vertical Character Hall cards.
- At level 5 or higher, test Cindervane defeat → three-second wait → half-health return, then confirm a second defeat within two minutes follows normal defeat.
- Talk to the northern Training Guide; replay and exit First Steps.
- Walk from town across the river bridge to quests and back. Build the mill and confirm the bridge remains open.
- Drag realm, food and item scrollbars; use their confirmation buttons and Enter. Encounter a new enemy, return to town and confirm its portrait is revealed only in that realm.
- Test a held attack and orientation change on a phone, then one two-device co-op match and arena with bots.
- Download/upload a profile and confirm discoveries and mastery progress.

The archive has not been deployed to your accounts. Matching Godot export templates are needed to produce the playable Web and Windows downloads. Browser graphics still depend on WebGL2; use the Windows edition and diagnostics when troubleshooting school browser crashes.
