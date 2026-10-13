# Deploy v141

## Render — required for ED submission rooms

From this archive's `FX_Crossroads/room_service/`, replace these three files in your existing repository:

- `rooms.mjs`
- `server.mjs`
- `package.json`

Commit and push, then deploy the latest commit on your existing Render Web Service. Keep Build Command `npm install` and Start Command `npm start`. Keep the existing room-service URL. No database or new environment variables are required. The server advertises `education_rooms`; the game tells users to redeploy if that feature is missing. Existing game networking protocol remains unchanged.

The service relays educational uploads while the private room is open. It does not retain a gradebook after the room closes. Received records are stored on the teacher's device and in their downloaded player profile.

## itch.io and Windows

1. Open this archive's `FX_Crossroads/project.godot` in Godot 4.5.1.
2. Let import finish. Re-export the Web preset to a clean output folder.
3. ZIP the exported Web files with `index.html` at the ZIP root. Upload that Web ZIP to your existing itch.io page as the browser-playable build.
4. Re-export Windows too if offering the downloadable edition, and replace its downloadable ZIP on itch.io.
5. Do not upload this editable source archive as the browser build.

## Quick classroom check

- Elder Ram: `studentModeOn`. Enter a class alias in the learning portfolio.
- Elder Ram: `teacherModeOn`, then `56Gt9` on the teacher's profile.
- Class view → Submission room → Host. Share the ED code with one student first.
- Student: Education Guide → Join teacher submission room → Join & send my progress.
- Teacher: Class view → Review work & mark outcomes. Save ratings; student accepts returned feedback.
- Download the teacher and student profiles before leaving shared computers.

Local passcodes are convenience gates, not secure authentication or paid-access protection. Do not distribute this as a secure online gradebook; that would require authenticated accounts and a server-side permissions system.
