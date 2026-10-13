# v12 — Public rooms and Join Random

This editable project includes the previous v11 content and mobile controls.

## Playing
Choose the game mode, then JOIN RANDOM. Search joins a waiting public room with space (maximum four players). Co-op searches match the selected realm; arena searches match the selected rule. Games already running and private rooms are excluded. If nothing is available, CREATE PUBLIC opens your own public room. The host starts when players have connected. Co-op supports 2–4 players; Ram Descent supports 1–4. Gate Defense and arena support up to four.

HOST defaults to a private room. Turn PUBLIC ROOM on before hosting, or toggle it while waiting as host. Code joining still works for public and private rooms. LEAVE ROOM disconnects and unlocks the mode selection. Mode, realm and arena rule stay fixed while in a room. Only v12 rooms participate in random matching.

## Required room-service update
The game source is ready, but the live room service has NOT been deployed from this package. Updating itch.io alone does not enable random joining.

The new server is in `room_service/`. Update the source repository used by your existing Render Web Service with these files. If the server repository contains only the service, copy the contents of `room_service/` to that repository's root. If you deploy this entire game project, set Render's Root Directory to `room_service` (or `FX_Crossroads/room_service` if that folder is also checked into the repository).

Use Node.js 22 or newer, build command `npm ci`, and start command `npm start`. Render supplies PORT; the service listens on 0.0.0.0. Deploy the updated service. Its HTTPS health endpoint reports version 12. Keep the current service URL if updating the existing service. If creating a different service, update ROOM_SERVICE_URL in scripts/arcade.gd to its wss:// address before exporting the game.

Run `npm test` in the server folder to check matching, capacity, room visibility, host permissions and disconnect cleanup. Then export the Godot web build and upload it to itch.io. Check in two browser tabs: public random join, private code join, and exclusion of a match after the host starts.

The service is an in-memory room directory and WebRTC signaling relay, not a gameplay relay. Restarting it clears its room list. Existing direct gameplay connections may continue; waiting parties should reconnect. The existing peer-to-peer connectivity constraints still apply; this update does not add a TURN relay.

## Validation
Godot 4.5.1 headless import completed without script errors. Existing network/hero regression checks passed. Five server unit tests passed. Live Render deployment and a two-browser WebRTC session must be checked after deploying the service.
