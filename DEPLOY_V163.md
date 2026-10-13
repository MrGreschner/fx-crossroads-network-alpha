# Deploy v163

Re-export Web and Windows from this project in Godot 4.5.1, then upload the Web export to itch.io and replace the Windows download. The source ZIP is not the playable Web export.

For Render, replace the existing room-service files with this project’s room_service contents in the same repository layout. Keep your existing analytics keys, disk, timezone, database path and Node settings. Set FX_GAME_VERSION to 163, keep build npm ci and start npm start, and deploy the latest commit. No new dependencies or analytics configuration are required. DEPLOY_V161.md has the full initial analytics setup if needed.
