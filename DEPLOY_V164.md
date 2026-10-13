# Deploy v164

Re-export Web and Windows from this project in Godot 4.5.1, then upload the Web export to itch.io and replace the Windows download. The source ZIP is not the playable Web export.

Use this Web export preset: html/experimental_virtual_keyboard is enabled and include_filter includes web/*.js. Both settings are needed for the touch keyboard support. On your own older preset, enable Experimental Virtual Keyboard and include web/*.js; using this project’s preset is simplest.

For Render, replace existing room-service files with room_service contents in the same repository layout, preserve analytics keys/disk/database/timezone/Node settings, set FX_GAME_VERSION to 164, and deploy. Build npm ci; start npm start. No new dependencies or paid services are required for this release.

After uploading, check Elder chat/password typing and closing/re-entering buildings on a real iPhone/Safari and Android/Chrome, then verify normal movement buttons return without rotating the device. Native/synthetic tests cannot prove mobile browser keyboard behavior.
