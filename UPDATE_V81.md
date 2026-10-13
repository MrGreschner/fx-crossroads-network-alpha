# v81 — Tournament arena and committed movement

## Arena and lobby
- Host chooses 2–8 player seats. Optional spectator host is a separate ninth connection with no fighter, combat targeting, match stats or mastery rewards.
- Balanced team battles support 1v1 through 4v4; free-for-all supports 2–8. Quest co-op is capped at two; other realm co-op, Defence and Descent remain four.
- Lobby settings use three clear rows; eight animated hero slots fit on two rows. Capacity and spectator participation are selected before creating a room.
- Full-map broadcast camera covers all five arenas with numbered fighter markers, readable health/KO cards and team totals. No character-follow camera is required. Terrain rendering uses fewer tiles at this zoom.
- Public listings show the correct player capacity and exclude the spectator from the player count. Match/reconnect packets retain spectator and seat settings.
- Three-second ready countdown blocks combat/movement at match start. Connection progress is visible, online solo shows its eight-second offline fallback countdown, and general room connections time out after 30 seconds.

## Heroes
- Burrowick commits to one direction per short digging stroke, pauses above ground to change direction, and covers less distance. Attacking stops movement; the fast 560-range Pounce is unchanged. Cave-in trails remain visible.
- Nullweaver special follows cursor distance within 500 range and respects walls. The triangle rotates 180 degrees and damage follows the visible edges. Mobile retains aim-stick targeting.
- Kite Corsair Windlass Swing lasts 1.65 seconds instead of 0.85, without increasing its one-hit-per-enemy damage.

## North Gate
All v80 changes included: fixed distant enemy entrances, destructible outpost checkpoints, synchronized health/rubble, and 20% slower guards. Wave notices explain the longer approach.

## Validation
Local Godot gameplay tests cover eight fighters plus spectator, all five map spawn layouts, guest snapshots, balanced teams, no spectator rewards, committed digging, free triangle aiming/rotation and extended swing. Native rendered lobby/broadcast views checked. Room-service tests include real local WebSocket connections for eight fighters plus host, capacity rejection and signaling. School-device end-to-end WebRTC play and sustained nine-device performance still need a deployment smoke test.

## Deployment
Complete editable Godot source. See MULTIPLAYER_RECOVERY_GUIDE.md for Render v15 steps. Deploy service before a fresh Web export. No new database, service URL or environment variables. Current Render commands remain npm install and node server.mjs. All participants must use this build. Nothing has been published by this update.
