# Deploy v147 — update itch.io AND Render

1. Back up profiles. Extract this editable project into a fresh folder; open `project.godot` in Godot 4.5.1, import and run it once. The source ZIP is not a playable itch.io Web export.
2. Export Web with `index.html` at the root of its upload ZIP. Export Windows Desktop from the same v147 project, keeping EXE/PCK/DLL files together. Replace both uploads on itch.io. Verify the build says v147.
3. Update the GitHub files used by your Render service. Copy **`server.mjs`, `rooms.mjs`, `package.json`, `package-lock.json` and the new `release.mjs`** from `room_service/`. Include other service files if updating the whole folder. `server.mjs` imports `release.mjs`; omitting that new file prevents service startup.
4. In Render → Environment set **`FX_GAME_VERSION` = `147`**. Keep the current service URL, root directory and other settings. Build: `npm install`. Start: `npm start`. Node >=22. Redeploy.
5. Visit **https://fx-crossroads-rooms.onrender.com/release**. It should display `{"game_build":147,"version":"v147"}`. This is the release advertised to installed games. No database is needed.
6. Have students refresh the browser game or install the new Windows download. A v146/older game attempting multiplayer now gets an update/save-first message. Once on v147, desktop launch checks also detect future releases automatically.

If staging Render before itch.io, temporarily set FX_GAME_VERSION to the currently published build (e.g. 146), then change it to 147 after BOTH downloads and browser export are published. Do not advertise a release that cannot yet be downloaded.

## Future updates
Update the client build constant and diagnostic/export labels when making a new version, publish the Web and Windows builds, then set FX_GAME_VERSION to that version and redeploy Render. The environment value represents the **published playable game**, not the room-protocol number. Test the endpoint and one native launch.

## School smoke check
- New profile: Grove available, other official realms locked with a clear explanation.
- Grove clear unlocks beginner realms; repeat Grove wins alone do not unlock medium.
- Death in solo Grove: Continue restores health/XP and same enemies. Enemy discovery persists; no mastery/clear reward. Play again earns progress normally.
- Solo Descent continue does not increase legitimate best-clear depth; multiplayer has no Continue.
- Shaft five shows the floor-five requirement; a legitimate Descent floor-five clear removes it.
- Desktop Options → Check for game updates. A newer advertised release shows backup instructions and the download link; restore the correct FX_GAME_VERSION afterwards.

Headless regression checks and service HTTP/WebSocket tests are included. Visually inspect desktop/mobile layouts and test actual itch.io/Render connectivity before inviting students.
