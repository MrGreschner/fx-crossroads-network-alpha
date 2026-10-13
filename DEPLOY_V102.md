# Deploy v102

## Render — update before uploading the game
1. In the GitHub folder Render builds from, replace **rooms.mjs**, **server.mjs**, **package.json**, and **package-lock.json** with the files in this archive’s **room_service** folder.
2. If your repository includes tests, copy all room_service/*.test.mjs files too; npm test references the new v102 test.
3. Commit, then let Render auto-deploy or select **Manual Deploy → Deploy latest commit**.
4. Keep **Build Command: npm install** and **Start Command: node server.mjs**. Keep your current root directory, service URL and environment settings. Use Node 22 or later. The service now reports **version 27**.

## itch.io
1. Extract this ZIP into a fresh folder and open **FX_Crossroads/project.godot** in Godot 4.5.1 with matching export templates.
2. Export Web into an empty directory using **index.html**. Keep threads disabled and the included diagnostic HTML head settings.
3. ZIP the exported files with index.html at the ZIP root. Replace your playable HTML5 upload on itch.io. This editable source ZIP is not itself a browser game upload.
4. Ask players to close old game tabs and reload the new version. Protocol 27 games cannot join older game rooms.
5. On two school PCs, test several matches, hero changes, deaths, teleports, disconnect/rejoin and host kicking. Try Options → School performance ON / 30 FPS on weaker computers. Download diagnostics if graphics loss recurs before restarting Chrome.

Export the downloadable Windows build separately with matching templates and the existing Windows setup instructions. No compiled Web/Windows build or automatic deployment is included here.
