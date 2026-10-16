# FX Crossroads — Alpha T4.16

Update BOTH the itch.io client and the existing Render game service. This is a separate networking alpha, not the v169 main-game release. Do not replace the main-game page or merge the two projects yet.

## What changed

- Auto graphics keeps the same arena view, world coordinates and input layout while lowering raster resolution after sustained slow frames: 100% → 85% → 70%. At 70%, a 1280×720 view renders at 896×504, about 51% fewer game pixels. It does not reduce simulation frequency, projectile visibility, hitboxes, player counts or damage. It resets for a new match, retains its tier through a reconnect and does not oscillate up/down during a match. F6 switches between Auto and Full; Auto is the normal choice for the student lab with integrated graphics. Lower resolution can soften text and sprites.
- A sustained state gap of 750 ms pauses further local prediction, clears obsolete predicted actions and cancels held casts. A clear connection-delay message appears. Fresh authoritative state restarts the presentation timeline. An open socket receiving no state for over four seconds is closed so the existing resume flow can reconnect; this does not guarantee recovery from a complete network outage.
- Large bursts keep the latest full state before decompression. Reliable control packets/events are retained, and normal interpolation still uses a short history. The gateway also keeps less unsent snapshot backlog.
- Reports now retain client rendering resolution, quality changes, state stalls, worst state gap, reconnect attempts, authority work/encoding times, gateway loop timing, queue size and CPU measurements when the platform provides them. The dashboard deduplicates overlapping sample batches before computing its medians.
- Client, server welcome, `/health`, downloaded F8 reports and combined report exports identify **T4.16**. Combined database downloads are named `FX_T416_match_….json`. Existing historical reports remain in the database with their original per-sample versions.
- Prior movement, melee, projectile, mobile input, summon damage and goalie-wall fixes remain included. Reporting is skipped when the server explicitly says no database is configured; F8 still works locally.

## 1. Update the server using GitHub online

1. Download and extract `FX_Crossroads_Network_Alpha_T4_16_Server_Update.zip`.
2. Open the extracted **UPLOAD_TO_GITHUB** folder. Its contents include `network`, `network_service`, `scripts`, `assets`, `web`, `project.godot` and `Dockerfile.network`.
3. Open your existing server repository on GitHub at its **top level**. Choose **Add file → Upload files**.
4. Drag the **contents inside UPLOAD_TO_GITHUB** into that upload page. Keep the folder structure. Do not upload the ZIP itself or create an extra `UPLOAD_TO_GITHUB` folder inside the repository. Do not delete the existing project folders; these files replace/add only the required paths.
5. Commit the update to the branch used by Render. This is a cumulative update with 67 runtime files, including the previously missing network dependencies and the ground-effect atlas required by the newer client/server code.
6. In the existing Render game service choose **Manual Deploy → Deploy latest commit**, unless its automatic deployment has already completed successfully.
7. Open `https://YOUR-EXISTING-SERVICE/health`. Confirm **ready: true** and **build: T4.16**. Also check that reporting remains configured/ready. A filename or manifest in GitHub alone does not prove that Render deployed it.

Keep the existing service, paid instance, database, `DATABASE_URL`, report admin password and signing secret. No new service, database reset or SQL migration is required. The Dockerfile path remains `Dockerfile.network`; the established application path and server address stay the same.

The server update was applied to a clean local T4.13 source project, imported successfully and exercised in eight-player combat. The deployment still needs to complete successfully on your actual Render service.

## 2. Update the itch.io alpha

Upload `FX_Crossroads_Network_Alpha_T4_16_Web.zip` to the EXISTING networking alpha page, replacing its old Web ZIP. Keep it configured as an HTML/browser game with the existing fullscreen/mobile options. The ZIP contains `index.html` at its root.

Reload all test devices after both deployments. The lobby should say **Alpha T4.16**; the in-game diagnostics should say **T4.16 • server T4.16**. If the server still says T4.13, the Render update has not taken effect. Hold off on the test until both labels match.

The editable source ZIP contains the entire project if you want to inspect or export it in Godot 4.5.1. It is not the ZIP to upload to itch.io.

## Next school test

Use the lab without dedicated graphics again, leave F6 on Auto and try 2 players followed by 8. Let the match run for a few minutes so Auto has time to adjust. Note which computers still feel slow and whether the issue is low frame rate, delayed attacks or a visible connection-recovery message. If possible, keep the teacher's RTX computer in the same match as a comparison.

The automatic database reports remain the main evidence. Download the combined match JSON after the test; F8 is a backup if the database is unavailable. A school-wide routing or network congestion problem may still affect all players even if rendering improves.

## Validation and limits

- Existing local network suite passed: combat, all 80 heroes/240 ability calls, projectile families, movement/collision, mobile summon melee, local prediction, world buffering, latency/jitter, reconnect, 2/4/8-player load, Gladiator enemies, soccer movement and goalie wall expiry.
- New budget/recovery checks passed. Browser checks verified fixed logical view and accurate mouse/touch input at 100%, 85% and 70% raster resolution; native mobile room-code entry and real join/start also passed.
- A real exported Web client with seven network peers passed an eight-player match and recovered the same identity after a six-second simulated loss of state snapshots. This test used a local software renderer, not an Intel UHD 630 school PC.
- The cumulative patch applied to a clean T4.13 project passed an eight-player, 60-second local combat run without unexpected disconnects. This is a short regression/load check, not a production-duration soak test.
- SQL-backed ingestion/export and T4.16 report naming passed, including retention of the new correlated diagnostic fields. No changes to the school's real database were made here.

These checks verify implementation and local recovery. They do not establish a particular FPS or latency on the school's devices or network. The next on-site test is required before calling the alpha finalized.
