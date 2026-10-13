# Deploy v154

1. Back up your profile, extract this project into a fresh folder, and open `project.godot` in Godot 4.5.1. Let imports finish and run once.
2. Export **Web**. ZIP the exported files with `index.html` at the ZIP root and upload to itch.io as the browser build. Do not upload this editable-source ZIP as the HTML game.
3. Export **Windows Desktop** from the same v154 project. Keep its EXE/PCK/DLL files together in the downloadable ZIP and replace the Windows upload. Check both builds show v154.
4. In the GitHub repository for Render, copy `server.mjs`, `rooms.mjs`, `release.mjs`, `package.json` and `package-lock.json` from `room_service/` (or update the entire service folder). This update changes the default advertised build, not the room protocol.
5. **After Web and Windows are published**, set Render environment `FX_GAME_VERSION` to `154` and redeploy. Keep your existing service URL/root directory. Build command: `npm install`. Start command: `npm start`. Node >=22.
6. Open https://fx-crossroads-rooms.onrender.com/release and confirm `{"game_build":154,"version":"v154"}`. Have players refresh browser tabs or download the new desktop release. Do not advertise 154 before it is downloadable.

## Creation rollout checks

- Make a hero, finish a test, finalize and open Studio → Projects & Showcase. Share a frozen submission.
- On a separate teacher profile, import the file, play it, request a revision, then download the returned file.
- Back on the student profile, import feedback, edit a copy, retest and submit version 2.
- Approve that submission on the teacher profile; download a Showcase pack and import it on another player profile.
- Download/Upload Profile on a separate test profile and confirm projects, submissions and feedback survive.
- Keep examples labelled as examples. Avoid student personal information in public packs.
- For a public featured release, replace content/workshop/showcase.json with the teacher-approved pack before export. Files are locally editable; teacher passcodes are classroom shortcuts, not secure online authentication.

## Arena rollout checks

- Open Gladiator Arena: Sinking Sands selected, AI Medium selected.
- Choose Easy, add 1–3 AI and start solo. Confirm bots move and use their kits.
- Host with Easy, join from a second device, switch difficulty and reconnect. Verify selection agrees.
- Choose Wildbloom or Coliseum and check lighter enemy population.
- Enter town/portal/Descent and check the subtle caption.

## Previous realm rollout checks

- Fresh profile: Grove and Quarry open; Honeyglass/Elementary explain their requirement. Tutorial results can launch Grove directly.
- Clear Grove or Quarry; both next realms open. Clear either next realm; Sunfield and Rink open.
- Walk the starter routes; check the first encounters do not spawn on arrival.
- In Sunfield, walk behind canopy clumps and check the route stays clear.
- In Rink, enter a blue cracked patch: momentum continues until you reach snow.
- In Petalbrook, clear all patrols and confirm the guardian seal opens.
- Verify Shattered Oath guardians move in Playtest/GameDev.
- Host one co-op match and verify the second player sees the same actors, map and ice behaviour.

The existing Studio, education, Market, profile and practice-continue features remain included. Read UPDATE_V154.md for the full unlock table. Local checks are recorded in RELEASE_CHECKS_V154.md; test actual itch.io and Render connectivity after publishing.
