# v153 — lighter arena setup and arrival effects

- Sinking Sands is the default Gladiator Arena, including the initial picker and room-service fallback. Existing explicit map selections remain selectable.
- Wildbloom Glade has 3 regular enemies and 1 mini-boss, down from 6 and 2.
- Crossroads Coliseum sends 2 enemies every 18 seconds, down from 3 every 12 seconds, with at most 6 regular enemies alive instead of 12.
- Easy AI is available alongside Medium and Hard. Medium remains the default. Easy thinks every 0.65 seconds instead of Medium's 0.36, moves 10% slower, leads targets less accurately, dodges less often and spaces secondary/special decisions. Health and damage remain unchanged. Difficulty carries through room settings, match starts, snapshots and reconnects.
- Area entry uses a quiet fading caption. The full-screen tint and large expanding ring are removed; hero attacks and combat telegraphs remain unchanged.

Local arena gameplay/settings checks passed. Room service: 70 tests passed. Godot import passed. Check browser visuals and actual online connectivity after publishing.

## Publishing

Export Web and Windows from this project. Update Render's `rooms.mjs` to preserve Easy difficulty and `release.mjs` to advertise this build. After both itch.io uploads are live, set `FX_GAME_VERSION=153` and redeploy. Full export/service instructions are in DEPLOY_V153.md. This ZIP is editable source, not a browser export.
