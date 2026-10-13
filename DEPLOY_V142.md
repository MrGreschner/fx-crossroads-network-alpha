# Deploy v142

## Render

**No Render changes are needed if you already deployed the v141 room service with `education_rooms`.** The v142 additions use existing classroom and game connections; room-service files and game networking protocol are unchanged.

If you have not deployed that education service yet, use the current archive's `room_service/rooms.mjs`, `server.mjs` and `package.json` in your existing GitHub/Render repository. Keep Build Command **npm install**, Start Command **npm start**, and your current root directory and URL. See DEPLOY_V141.md for the initial education-room setup.

## itch.io

1. Extract this editable archive into a fresh folder; open its `FX_Crossroads/project.godot` in Godot **4.5.1** and let import finish.
2. Install matching Godot export templates if needed.
3. Export the **Web** preset to a clean output folder. ZIP the exported files with **index.html at the ZIP root**.
4. Replace the browser-playable build on itch.io. This editable source ZIP is not the Web upload.
5. Close old tabs and reload the new build before class testing.

## Windows download

Run **BUILD_WINDOWS.cmd**, or export the Windows preset. The build script names the downloadable ZIP **exports/FX_Crossroads_Windows_v142.zip**. Replace the downloadable Windows file on itch.io too. The main-menu download link uses your existing configured game/download page; that hosting arrangement is unchanged.

The supplied archive is editable source, validated in Godot on Linux. It contains no pre-exported Web or Windows binary. Native Windows and browser/device testing must be performed after your exports.

## Quick checks before class

- Teacher Mode: Elder Ram → `teacherModeOn` → `56Gt9`. **Class view → Example**; inspect all three quality levels and an unfinished module.
- Game Dev: `gameDev` → `R4ms!90`. Class view examples are available without recording real marks.
- Student Mode: `studentModeOn`. Education Guide → one business module → its challenge. Run a trial, add a reflection, attach it and download the profile.
- Host one public or private game. Check crown visibility for a player who has earned at least 1,000 eligible damage in this build.
- Keep teacher/student profile backups on shared computers. Example work is not included in class backups.
