# Deploy v140 — Render plus game exports

1. Keep a backup and extract this complete editable source ZIP into a fresh folder. Open **FX_Crossroads/project.godot** in Godot **4.5.1** and let imports finish.
2. Replace **rooms.mjs**, **server.mjs** and **package.json** in your existing GitHub room-service repository with the files in **room_service/**. Commit and let Render auto-deploy, or choose **Manual Deploy → Deploy latest commit**.
3. Render settings stay **Build: npm install** / **Start: node server.mjs** (or your existing npm start). Keep the working WebSocket URL, PORT handling and Node 22+. No database or new dependencies are needed.
4. Export **Web** into an empty folder using matching Godot export templates. ZIP the playable export with **index.html at the root**, then replace the itch browser-playable upload. This editable project ZIP is not the browser-playable export.
5. Re-export **Windows**, ZIP that output and replace the downloadable upload as well. This build environment does not contain Godot export templates, so playable exports must be made in your Godot installation.
6. Have students refresh to the new game version. Gameplay protocol 32 and Partner Up remain compatible with the current service. The new **assessment_review** capability is needed for teacher review codes; local/file marking works without it.

## School release check

- On a student machine: Student Mode ON → DES1020 → save brief → make a prototype → save snapshot → submit.
- Download/import the player ZIP and verify the journal, artwork and submission survived.
- On a second machine: teacher / fx97 → join RV code. Verify no portfolio arrives before the student approves. Mark two outcomes, return feedback, accept it on the student machine and verify it persists after reopening.
- Try a decline, teacher disconnect, Stop sharing and an expired/incorrect code. Check ordinary multiplayer and Partner Up still work.
- Review an external portfolio JSON without replacing the teacher's player profile.
- In Game Dev and Playtest, verify assessed evidence cannot be written. Exit to normal profile to record student work.
- Test actual school browsers/GPUs/network; local automated checks do not establish classroom performance or firewall behaviour.
