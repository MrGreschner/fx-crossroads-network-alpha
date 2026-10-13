# Deploy v157

1. Extract this editable project ZIP into a fresh folder and open project.godot in Godot 4.5.1. Let assets import.
2. Export Web using your existing preset. Upload the resulting web export ZIP to itch.io (not this source ZIP). Keep index.html at the export ZIP root.
3. Export Windows using the existing preset/BUILD_WINDOWS.cmd and upload that download separately. Verify both exports show v157 in Options diagnostics.
4. Update Render's FX_GAME_VERSION environment variable to 157, then redeploy. If using the bundled default rather than an environment variable, update room_service/release.mjs. No new server dependencies or room-message types are needed for this update.
5. Keep the existing download URL and signaling URL settings. Back up profiles before replacing installed copies.
6. Smoke-test: send a gathering crew, brew the starter tonic, pack it, use it in a realm, play a lodge trial, and test two updated multiplayer clients with an item-enabled match.

Gathering, brewing and medals are saved locally and included in profile backups. Do not distribute old client builds alongside v157; crafted potion definitions are new in this client.
