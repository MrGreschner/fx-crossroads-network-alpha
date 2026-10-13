# Deploy v101

## Render
1. Replace **rooms.mjs**, **package.json**, and **package-lock.json** in the GitHub folder Render builds from, with the versions under room_service/ in this archive. Keep server.mjs from this archive alongside them (it is unchanged).
2. If you keep the repository's test suite, also upload room_service/v101.test.mjs and the other existing tests, because npm test now includes the new test.
3. Commit the changes. Let auto-deploy run or choose Manual Deploy → Deploy latest commit.
4. Leave Build Command as **npm install**, Start Command as **node server.mjs**, and your existing root directory, URL and environment settings unchanged. Protocol remains 26; package patch version is 26.0.1.

## itch.io
1. Extract this editable source ZIP into a fresh directory and open FX_Crossroads/project.godot in Godot 4.5.1.
2. Install matching export templates if needed, then export Web to a fresh directory with index.html as its entry file. Keep threads disabled.
3. ZIP the exported files with index.html at the root, and replace the playable HTML5 upload on itch.io. Do not upload this source ZIP as the playable browser game.
4. Restart Chrome once before testing the newly uploaded build. Use Options → School performance ON / 30 FPS. Test two PCs joining, changing heroes, leaving, being kicked and playing several consecutive matches.
5. If the graphics connection is lost again, use Download diagnostic report before restarting Chrome. This hardware-specific crash is not yet confirmed resolved.

The downloadable Windows build must also be exported separately using the existing Windows preset / tools/build_windows.ps1 and matching templates. Source alone is not a playable executable. Nothing has been deployed automatically.
