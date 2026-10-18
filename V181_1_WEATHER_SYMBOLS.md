# v181.1 — mastery symbols and moving weather

Client update on top of v181. Keep the v181 Render server and existing database.

- Mastery labels explicitly use the bundled Crossroads UI font, including check marks, circles, and two-way arrows. No installed system font is needed.
- Rain falls diagonally at a steady speed using a monotonic animation clock. Dev time/weather previews no longer freeze rain or puddle ripples.
- Cloud shadows and mist drift over world positions. Walking, dashing and camera resizing do not drag the weather with the player.
- Weather uses bounded, culled draw primitives; no extra textures, lights or postprocessing.
- Real-time Edmonton day/night, fishing schedules, saves, and multiplayer remain unchanged.

Upload Crossroads_v181.1_Web.zip intact to itch.io. Use the Editable archive for Godot debug. No server redeploy or database migration is required if v181 is already deployed.
