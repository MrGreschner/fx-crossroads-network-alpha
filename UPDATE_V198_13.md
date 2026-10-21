# Crossroads: Realms Beyond — v198.13

Shatterfloor now shows an actual fall between decks, instead of instantly moving the player to a different floor. Built on v198.12 with the existing town performance work and all accepted gameplay/art changes retained.

## What changed

- A shared 0.85-second falling phase: crumbling tile fragments, a falling hero pose with a small tilt/size change, downward trails, and a smooth camera journey to the next deck.
- A labelled landing ring previews the destination. Floor/status labels show when players are falling or have landed.
- Cracks grow across each tile, with a shrinking timer strip. Warning length remains 0.85 seconds, retaining the existing pace.
- A 0.75-second landing grace period gives players time to steer away from a hole and prevents immediate shove chains. Missing tiles remain dangerous when grace ends.
- Falling players cannot move, shove, hop or be shoved. The server owns the fall and landing; snapshots include the complete transition so clients can resume an ongoing fall.
- Final-floor elimination waits for the fall animation. Placement ties use the time the floor gave way, and rounds wait for ongoing drops to finish.
- Landing ignores stale positions from the previous deck, preventing a brief snap back caused by the normal multiplayer interpolation buffer.
- Off-screen tiles are culled individually and cracks use cheaper rendering. Visual timers interpolate between snapshots without changing authoritative game rules.

## What the supplied logs showed

The detailed performance export contains other arena modes. The separate activity export includes two actual Shatterfloor gameplay intervals, with eight players (seven AI), on an Intel UHD 630. Interval averages were about 25.5 and 34.6 FPS, with a minimum of 15 FPS and up to 703 reported draw calls. Average reported network delay was about 364 and 245 ms, with a peak of 1,357 ms; authority stayed around 60 Hz. These indicate both client rendering pressure and network delay. They do not isolate individual falls, and their release labels are unknown/legacy, so they cannot establish performance of v198.12.

This update addresses the confirmed instant-deck jump, landing-buffer snap and unnecessary tile/crack rendering. It does not claim to eliminate network latency. Filtered, anonymous log findings and automated results are included in the editable project's validation/v198_13 directory.

## Validation

- 48 Shatterfloor checks passed from source and from the rebuilt web resource pack: timed falls, mid-fall snapshot resume, movement/action blocking, landing grace, off-edge falls, stale-buffer recovery, final-floor scoring, timeout/round cleanup, and seven practice AI finishing all three rounds.
- Eight real WebSocket clients passed FFA and teams: replicated fall endpoints/timing, rejected mid-fall hops, duplicate-action protection, shared controls, scoring and all three rounds.
- 44 Colour Clash / Crown Chase regression checks and 52 prior combat/HUD checks passed.
- Native OpenGL rendering was checked at departure, mid-fall, approach and landing. In a deliberately heavy full-deck cracking scene, median draw calls fell from 893 to 474 (about 47% fewer), reproduced with the test order reversed. Intact-deck calls were essentially unchanged. Software-rendered process timings varied substantially between runs; this is a draw-call reduction, not a measured student-device FPS gain. Comparison logs are included.
- ZIP integrity, shipped script consistency and a clean server import/start are checked before delivery.

## Manual deployment

1. Back up your current project/repository and keep your existing Render database, environment variables, account/save storage and keys.
2. Extract Crossroads_v198_13_Server_Update.zip at the existing server repository root. Keep the existing Render service and database. Deploy using Dockerfile.network as before.
3. Confirm the Render /health endpoint reports V198.13-shatter-falls and ready: true.
4. Upload Crossroads_v198_13_Web.zip to the existing itch.io HTML game after the server is ready.
5. Keep Crossroads_v198_13_Editable.zip as the complete editable Godot project.

No schema changes, database resets, account resets or key replacements are required. This update is not deployed automatically. Real-device/browser playtesting with students remains, especially on the machine that reported low FPS and high latency.
