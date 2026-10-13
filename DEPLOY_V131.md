# Deploy v131

## Render
There are no new room-service changes in v131. If you already deployed v130 (protocol 30), leave Render unchanged.

If you have not deployed v130 yet, replace `rooms.mjs`, `server.mjs`, `package.json` and `package-lock.json` with the copies in this ZIP's `FX_Crossroads/room_service/`. Keep your existing repository layout and root directory. Build command: `npm install`. Start command: `node server.mjs`. Keep the service URL and environment variables. Node 22 or newer is required. Deploy the latest commit and wait for Live. Classroom Broadcast requires protocol 30.

## Godot and itch.io
1. Extract this editable source ZIP, then open `FX_Crossroads/project.godot` in Godot 4.5.1 with matching export templates.
2. Test the west-side Studio and Relay entrances, Mistglass battle and End Battle button, a daily quick-play action, and Field Research (`playtest` in Elder Ram chat; F8 for tools). Confirm your original profile returns after exiting Research.
3. Export Web into an empty folder. ZIP all exported files with `index.html` at the ZIP root. Upload that exported Web ZIP to itch.io as the browser-playable file. This editable source ZIP is not the playable export.
4. Rebuild and replace the downloadable Windows ZIP if you offer it.
5. Reload all test devices into the new build. Check a multiplayer match, the Game Dev insignia on another player, and Classroom Broadcast if you use it.

The source was tested locally. Matching Web/Windows export templates are not installed in this workspace, so school browsers, phones and the exported builds still need this final device check. No new service or environment variables are needed.
