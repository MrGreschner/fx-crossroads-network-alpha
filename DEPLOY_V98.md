# Deploy v98

## Render

No Render changes are needed if you are already using the current protocol-26 room service. This release keeps all room_service files unchanged. Leave the existing service URL and settings as they are (npm install / node server.mjs).

## Godot and itch.io

1. Extract this archive into a new folder and open FX_Crossroads/project.godot in Godot 4.5.1. Allow asset imports to finish.
2. Export the Web preset into a fresh folder, using index.html as the entry point. Use matching Godot export templates.
3. ZIP the exported files with index.html at the ZIP root. Replace the playable HTML5 upload on itch.io. Preserve the current mobile/fullscreen settings.
4. Re-export Windows if offering the downloadable edition. Build output names now use v98.
5. Reload the game on each device. Check the two new heroes in training and play one actual two-device match before students join. Keep the previous playable upload for rollback.

The editable source ZIP is not the playable Web upload. No deployment has been performed automatically.
