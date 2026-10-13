# Deploy v138 — Render update required for two-pencil Studio

## 1. Update the room service

This update changes Partner Up's protocol. It uses the existing Render service, with no new account server or dependencies.

1. In your GitHub room-service repository, replace **rooms.mjs**, **server.mjs** and **package.json** with the files from this project's **room_service/** folder. The functional live-edit change is in rooms.mjs. Its PNG support uses Node's built-in zlib, so no extra package or file is needed.
2. Commit the changes. Let Render auto-deploy, or choose **Manual Deploy → Deploy latest commit**.
3. Keep the current commands: **Build: npm install**, **Start: node server.mjs** (or your working npm start). Keep your existing PORT handling and WebSocket URL. Node 22 or newer remains required.
4. Wait for Render to show Live. A v138 client checks for the new studio_live capability and explains when the service needs updating.

Normal multiplayer still uses its existing protocol. Old Partner Up builds retain their legacy sessions; an old/new pair cannot join the same Studio session. Both students should load v138.

## 2. Export the game

1. Extract the full editable ZIP into a new folder and open **FX_Crossroads/project.godot** in Godot 4.5.1. Let imports finish.
2. Export Web with matching templates into an empty folder. ZIP the exported files with index.html at the root, then replace itch.io's browser-playable upload.
3. Re-export Windows and replace the downloadable game ZIP.

## 3. Classroom checks

- Save a new hero. Open Character Hall → Custom heroes; confirm it appears without any file upload. Also try Play in Training Yard.
- Main student opens Partner Up, creates a session and shares the SP invite code. The other joins it. Main chooses the active lab.
- Both open the same pose in Pixel Studio and draw in different areas at the same time. Both should see the combined strokes before Save image. Try enemy art and an ability frame too.
- Edit two different settings. Both should remain. Same pixel/setting deliberately changed twice should show the last edit received.
- Download shared on both machines. Back up player profiles before using shared computers. Main keeps the principal local project; the partner can retain a copy too.
- Check Idle Mining's construction/refining progress and a boost cooldown. These do not change mine earnings or timers.
- Save two workshop test reports, then open Tests & reports → Compare my last two tests.

Live drawing was checked with two native game instances using a local WebSocket service. Browser file handling and school-network latency still need the checks above. Export templates are not installed here; this ZIP is editable source, not the playable Web export.
