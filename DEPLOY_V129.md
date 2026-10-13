# Deploy v129

## 1. Update Render's room service

1. Extract the source ZIP. In the GitHub repository connected to your existing Render service, replace the files with those from `FX_Crossroads/room_service/`: `rooms.mjs`, `server.mjs`, `package.json` and `package-lock.json`. Keep the repository layout Render already uses. Test files are optional for hosting; copy them if you also run npm test.
2. Commit the files. Allow auto-deploy, or choose Manual Deploy → Deploy latest commit in Render.
3. Keep **Build Command: npm install** and **Start Command: node server.mjs** (npm start also runs this command). Keep the current root directory, service URL, environment variables and port settings. Node 22 or newer is required.
4. Wait for Live. The room service now advertises protocol 29, needed for the new spectator capacity. Old and new game builds cannot share a room; everyone should reload into the new build.

## 2. Re-export and upload to itch.io

1. Open this project's `project.godot` in Godot 4.5.1, using matching export templates. Test it locally first.
2. Export the Web preset to an empty folder. ZIP the exported files with `index.html` at the root. Upload that Web ZIP as the browser-playable file on itch.io. **Do not upload this editable source ZIP as the playable Web ZIP.**
3. Rebuild the Windows preset and replace the downloadable Windows ZIP if you offer that edition.
4. Reload on both test devices. Verify a tutorial defeat/retry, three-attack enemy test and Mistglass Rift battle. Host Descent as spectator and confirm the host is outside the player slots; check a second human can join. Test Battlegrounds with balanced teams and the broadcast dropdown.

The source has been validated locally, but your school browsers, network and exported Web/Windows builds still need this final device check. No additional Render service or environment variables are needed.
