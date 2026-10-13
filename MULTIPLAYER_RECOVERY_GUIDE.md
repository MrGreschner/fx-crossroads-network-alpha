# Current release: v91 / room service 25

Deploy the included `room_service` directory to Render when you release v91. Players in one room must use the same version. URL, environment variables and start command are unchanged. Export fresh Web and Windows builds from this source project.

# Current release: v84 / room service 18

Deploy the included `room_service` directory to Render before inviting players with v84. All players in one room must use v84. The service keeps older protocol rooms separate. The service URL and environment variables are unchanged. Export new Web and Windows builds from this source project.

# Deploy the v83 tournament update

The room service is now **version 17**. It remains a small Node WebSocket signaling service; gameplay still runs on the host. It does not need a database, new environment variables or a different service URL.

## Render

1. In the GitHub repository connected to your existing `fx-crossroads-rooms` Render service, replace `rooms.mjs`, `server.mjs`, `package.json` and `package-lock.json` with the versions in this project's `room_service` folder. Preserve the repository's existing directory structure.
2. Keep **Branch: main**. Keep the existing root directory pointing at the directory containing those files. If they are at the repository root, the root-directory field stays blank; if they are in `room_service`, use `room_service`.
3. Keep **Build command: `npm install`** and **Start command: `node server.mjs`**. The runtime is Node; Render supplies `PORT`. No extra environment variable is required.
4. Commit/push the files and let Render deploy, or select **Manual Deploy → Deploy latest commit**. The service log should say `FX Crossroads room service v25 ready`. Opening the service's HTTPS address should show JSON containing `"version":25`.
5. Export the v91 Web game into a new empty export folder. ZIP the exported files with `index.html` at the ZIP root and replace the playable itch.io upload. The editable source ZIP is not the playable Web ZIP. Everyone should reload into v91; old and new game protocols are separated in public browsing and new rooms require matching versions.

The source project keeps `wss://fx-crossroads-rooms.onrender.com` as its room-service address. If you use a different service, change `ROOM_SERVICE_URL` in `scripts/arcade.gd` before exporting.

## What players experience

- A signaling-service interruption can reconnect while healthy direct links keep playing.
- A stalled/broken gameplay link is detected after about four seconds. Battle simulation pauses while it repairs; no enemy damage is simulated during the pause.
- Players must leave the game tab/window open. A 45-second grace period allows the existing process to return. Reconnection preserves the match identity, health, inventory, wave/floor and mastery build.
- After that window, an absent co-op guest can be removed so the host continues. An interrupted arena has no ranked outcome.
- If the host has really crashed or closed, guests can restart the same non-PvP mode solo or return to town. A solo restart is a fresh battle.

A WebGL context loss is a separate graphics failure. Use the existing diagnostic-download prompt and Windows edition build tools for those machines. Reconnection does not make a graphics crash recoverable. This release does not provide host migration or a dedicated authoritative game server.

## Classroom verification

Use a private room with two matching v83 builds. Start Descent or Defence, note both health values and the floor/wave, then briefly interrupt one guest's network connection without closing its game. Confirm the pause, resume and unchanged vitals/progression. Repeat for the host's network connection. Test leaving explicitly: it should not leave a ghost room for 45 seconds. Test an interruption longer than the grace window and confirm the appropriate recovery choices.

For arena, confirm an interrupted match does not add wins, losses or draws. Test on the actual school Wi-Fi and computers; a local room-service test does not prove that a restricted network permits every WebRTC route.

The room server holds resume tokens only in memory. They are not player-profile credentials and are not written to exported profiles or diagnostics. A server restart discards room reservations. The room service still authenticates no persistent accounts and is not an anti-cheat server.

## New party features
The same deployment also enables public room lists and host-approved requests to active Defence/Descent games. No new Render environment variables or database are required. Public browsing lists waiting rooms only. Online solo sessions are private; friends need the code shown by Invite. Test a host at wave 6 accepting a level-one guest without restarting the wave or healing the host. Test a declined/expired request, a full party, and an attempted late arena join (rejected).

## Tournament hosting (v83 / room service v17)
Before hosting, choose Gladiator Arena, player seats (2–8), and optionally HOST AS SPECTATOR. That checkbox adds a separate host connection; it does not consume a player seat. Seats and host participation are locked for that room; leave and re-host to change them. Teams must be balanced, up to four per side. The spectator gets a full-map broadcast view, numbered player markers, health strips and scores. Esc, then Enter leaves the broadcast and closes the hosted match.

Every start has a three-second ready countdown. Offline solo fallback counts down from eight seconds if a private room cannot be prepared. Defence enemies now start at the distant road entrances; travelling to the front takes time, and a notice explains that they are marching.

Deploy the four service files above first, verify service version 17, then export/upload the v83 game. Test eight school devices plus the projector host before a tournament. The spectator still runs the authoritative simulation: use the more capable classroom computer for hosting. Server tests cover all nine connections and signaling; they cannot verify your school's peer-to-peer firewall routes or sustained graphics performance.

## Arena practice bots (v83)
Select 0–3 bots before hosting. They reserve fighter seats; they do not require WebRTC peers. Any bot match grants damage-only hero mastery and no PvP records or town-task progress. Play Solo works offline with bots. Leave the room before changing its bot count, spectator format or capacity.

## North Gate and AI difficulty (v83)
North Gate is capped at three players, including late joins. Choose Medium or Hard AI before hosting. Arena hosts can choose zero to three practice bots. New rooms require matching v83 clients (protocol 17). No additional environment variables or Render resources are required.
