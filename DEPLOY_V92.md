# Deploy v92 to Render and itch.io

This ZIP is the editable Godot source, not the playable browser ZIP. Keep a backup of the currently published build and download your player profile before replacing it.

## Render — update the existing room service

1. Unzip this release. In the GitHub repository already connected to Render, replace **rooms.mjs**, **server.mjs**, **package.json** and **package-lock.json** with the files from **FX_Crossroads/room_service/**. Preserve the existing repository layout. The test files are optional for hosting; copy them too if you want to run the included tests there.
2. Keep your existing Node service and **Branch: main**. **Root Directory** stays blank if those four files are at the repository root. If you placed them inside room_service, set it to **room_service**.
3. **Build Command: npm install**. **Start Command: node server.mjs**. Keep the existing service URL and environment variables. Render supplies PORT; no new variable or separate service is needed for this update. Use Node 22 or newer, as declared in package.json.
4. Commit/push the changed files. Let auto-deploy run or choose **Manual Deploy → Deploy latest commit**. Check the service log for **FX Crossroads room service v26 ready**. Opening its HTTPS address should return JSON containing **"version":26**.

## Godot and itch.io — fresh playable build

1. Open the extracted **project.godot** in Godot 4.5.1, the version used for this release's checks. Install matching export templates. Allow the initial asset import to finish.
2. Export the Web preset to a new empty folder, with **index.html** as its entry point. ZIP the exported files themselves so **index.html is at the ZIP root**. Do not upload this editable-source archive as the HTML game.
3. On the existing itch.io edit page, replace the playable Web ZIP with that new export. Retain the existing HTML5/mobile/fullscreen settings. Save the page. Export Windows separately if you also offer the downloadable edition; tools/build_windows.ps1 and the build workflow are updated to v92.
4. Ask every player to reload so they use v92. Versions are isolated in room browsing; mixing cached builds does not make a valid new v92 room. Test one solo arena with bots and one real two-device multiplayer match before students join.

## Short release check

1. Enter the northern battlefield clearing or choose Battlegrounds in Gather Your Party. Confirm both maps and 3v3 / 4v4 settings before hosting.
2. Use **six devices/accounts for 3v3**, or eight for 4v4. Check team balancing, public-room settings, one personal barracks per hero and simultaneous army spawning.
3. Buy recruits/upgrades at your own barracks. Confirm purchases cannot be made from another player’s barracks or remotely from the middle of the map.
4. Fight for the middle item market. Confirm hero damage, support, corpse summoning, unit bounties and hero respawns.
5. On Iron Rain, dodge orange circles and verify strikes hurt both sides.
6. Destroy opposing barracks and heart, then return to the same party and start another match.
7. Test a phone’s touch Interact button and landscape rotation, a disconnect/reconnect, existing Arena with bots, and a solo Realm/Descent/Defence run.

The included local simulations and room-service tests passed, but a real six/eight-device classroom match has not been run here. Do that short match before opening Battlegrounds broadly; troop economy and match length should be tuned using students’ playtests.

The archive has not been deployed to your accounts. Matching Godot export templates are needed to produce the playable Web and Windows downloads. Browser graphics still depend on WebGL2. The Render room service does not offload the army simulation: the host computer runs it. Prefer the downloadable edition on a capable host for large matches.
