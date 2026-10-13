# Deploy v149 — update itch.io AND Render

1. Back up profiles. Extract this editable project into a fresh folder; open `project.godot` in Godot 4.5.1, import and run it once. The source ZIP is not a playable itch.io Web export.
2. Export Web with `index.html` at the root of its upload ZIP. Export Windows Desktop from the same v149 project, keeping EXE/PCK/DLL files together. Replace both uploads on itch.io. Verify the build says v149.
3. Update the GitHub files used by your Render service. Copy **`server.mjs`, `rooms.mjs`, `package.json`, `package-lock.json` and the new `release.mjs`** from `room_service/`. Include other service files if updating the whole folder. `server.mjs` imports `release.mjs`; omitting that new file prevents service startup.
4. In Render → Environment set **`FX_GAME_VERSION` = `149`**. Keep the current service URL, root directory and other settings. Build: `npm install`. Start: `npm start`. Node >=22. Redeploy.
5. Visit **https://fx-crossroads-rooms.onrender.com/release**. It should display `{"game_build":149,"version":"v149"}`. This is the release advertised to installed games. No database is needed.
6. Have students refresh the browser game or install the new Windows download. A v146/older game attempting multiplayer now gets an update/save-first message. Once on v149, desktop launch checks also detect future releases automatically.

If staging Render before itch.io, temporarily set FX_GAME_VERSION to the currently published build (e.g. 148), then change it to 149 after BOTH downloads and browser export are published. Do not advertise a release that cannot yet be downloaded.

## Future updates
Update the client build constant and diagnostic/export labels when making a new version, publish the Web and Windows builds, then set FX_GAME_VERSION to that version and redeploy Render. The environment value represents the **published playable game**, not the room-protocol number. Test the endpoint and one native launch.

## New v149 smoke check
- Fresh profile → Market → Basic setup → Open Market. Confirm stock, market cash and countdown.
- Collect mine materials, meet a town project requirement and Build. Confirm exact material deduction and no CC charge.
- Visit Gleam Atelier above Squirrel Post; choose cosmetics and return to town.
- Die in a solo realm and Continue. Confirm the practice badge and unobstructed health bar.

## Realm Builder smoke check
- Open Crossroads Studio → Realm Builder; load a new example.
- Zoom to spawn, paint a road, undo/redo, pan to another area using the minimap.
- Resize to 128 × 96, choose rain/dusk, and place an enemy and a tree.
- Finalize & Play: walk the route, attack, restart, end the test and confirm edits survive.
- Download the realm and your profile; import into a separate test profile and confirm terrain/weather/art remain intact.

## School smoke check
- New profile: Grove available, other official realms locked with a clear explanation.
- Grove clear unlocks beginner realms; repeat Grove wins alone do not unlock medium.
- Death in solo Grove: Continue restores health/XP and same enemies. Enemy discovery persists; no mastery/clear reward. Play again earns progress normally.
- Solo Descent continue does not increase legitimate best-clear depth; multiplayer has no Continue.
- Shaft five shows the floor-five requirement; a legitimate Descent floor-five clear removes it.
- Desktop Options → Check for game updates. A newer advertised release shows backup instructions and the download link; restore the correct FX_GAME_VERSION afterwards.

Headless regression checks and service HTTP/WebSocket tests are included. Visually inspect desktop/mobile layouts and test actual itch.io/Render connectivity before inviting students.
