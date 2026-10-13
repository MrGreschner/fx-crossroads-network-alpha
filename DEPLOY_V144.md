# Deploy v144

Use this version instead of v143 when uploading today.

1. Download a backup of any student/player profile before replacing the game.
2. Extract this editable project into a new folder; open `FX_Crossroads/project.godot` in Godot 4.5.1 and finish asset import.
3. Export **Web** with matching Godot templates. Zip the Web output with `index.html` at the ZIP root, then replace the browser-playable itch.io upload. Do not upload the editable project as the HTML game.
4. Export **Windows Desktop** from the same project, package its executable and exported files, and replace the downloadable itch.io build. The supplied Windows build script names its output v144.
5. Test the uploaded build: Adventures → Build, trade & create → Idle Mining; collect metals, forge a copper bar, and use Market to prepare it for sale. Check both screens return to town. Try one school computer and a phone in landscape, then test a two-player match.

**Render:** the room-service files and network protocol are unchanged. No Render redeploy, build-command adjustment or environment-variable change is needed if running the v142/v143 service.

All multiplayer participants should use the same current game build. v144 reads existing profiles and adds empty new metal accounts and Market stock entries without resetting prior progress. New v144 profiles should not be loaded into an older game that lacks foundry validation.

Local automated tests and native visual captures passed. Web and Windows exports still require their target-device spot checks; this package cannot guarantee that every school Chrome graphics driver avoids context loss.
