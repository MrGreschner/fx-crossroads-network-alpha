# Deploy v145

1. Back up current player/student profiles.
2. Extract this editable project to a fresh folder. Open FX_Crossroads/project.godot in Godot 4.5.1 and allow import to complete.
3. Export Web. Zip the exported Web files with index.html at the ZIP root and replace the browser-playable itch.io upload. This editable project ZIP is not an HTML game export.
4. Export Windows Desktop from the same source; replace the Windows download too. The Windows build script now names its output v145.
5. On a school computer, check the courtyard, mountain entrances, Food Stand label, Academy stations and doorway. Test Student toggle, Media minimize, normal zoom and a multiplayer match. Both participants should use v145.

Render is unchanged from v144. Because your server was several versions behind, deploy the included room_service/rooms.mjs, server.mjs and package.json once if you have not already updated it. Keep the existing Render service URL and root directory, Build: npm install, Start: npm start, Node >=22. No database or new environment variable is required. Once updated to the v144 service, there is no further server change for this update.

Profiles retain existing work and progress. Permission-removal commands change the current profile; use its updated download to carry those changes to another machine.
