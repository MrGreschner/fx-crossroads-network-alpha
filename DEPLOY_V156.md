# Deploy v156

1. Extract this ZIP, then open FX_Crossroads/project.godot in Godot 4.5.1.
2. Export Web with the existing preset. Upload the exported Web ZIP to itch.io as the browser-playable game. This source-project ZIP is not the Web export.
3. Export Windows with the existing preset and replace the Windows download on itch.io.
4. For Render’s downloaded-version notification, set FX_GAME_VERSION to 156 and redeploy (or update room_service/release.mjs from this project if using its default). No room protocol changes or new dependencies are required for the grid.
5. Check Hall → Grid view; select a hero, close without choosing another, and try custom heroes. Check the same selector in hosted and joined rooms. Confirm portraits and names remain readable on a phone.

Do not deploy until your exported browser and Windows versions both show v156.
