# T4.8 — shared melee attachment and network jitter handling

## This release needs BOTH the server update and the itch.io update

Earlier T4.1–T4.7 releases were client-only. T4.8 adds owner metadata to several server effect records and a gateway RTT probe. For the complete fix, update the GitHub/Render server first, then the FX Connections Lab itch.io client. Your existing paid Render plan and protocol 3 remain suitable for this test; no plan change is requested.

1. Extract FX_Crossroads_Network_Alpha_T4_8_Server_Update.zip into the LOCAL GitHub repository folder that already contains Dockerfile.network, project.godot, network/ and network_service/. Preserve the ZIP's folder structure and allow matching files to be replaced. Keep the other existing project files. Do not delete the project or put these files inside an extra FX_Crossroads subfolder. This package contains changed runtime files relative to the deployed T4 baseline, plus its own instructions/manifest.
2. In GitHub Desktop, review the changed files, commit as 'T4.8 shared combat presentation and jitter buffer', and Push origin. Deploy the latest commit on Render if automatic deployment does not run. Deploy between matches: replacing the server disconnects its active rooms.
3. Check https://fx-crossroads-network-alpha.onrender.com/health shows ready: true, build: T4.8 and protocol: 3. If deployment fails, retain the deploy log; the previous successful Render deployment/commit is the rollback point.
4. Upload FX_Crossroads_Network_Alpha_T4_8_Web.zip to FX Connections Lab on itch.io and refresh EVERY client. The footer should say T4.8. The F8 report should show server_build: T4.8 and a nonnegative gateway_rtt_ms after the first probe, normally within two seconds.

FX_Crossroads_Network_Alpha_T4_8_Source.zip is the complete editable Godot project and backup. The smaller Server_Update ZIP is the easier way to update the existing T4 GitHub repository. These are prepared files; the hosted server has not been changed by the assistant.

## Shared drawing fix

The previous melee anchor fixed one renderer; Little Menace uses a different renderer. T4.8 gives combat helpers a drawing-only owner-position lookup, shared across the 80 official heroes. It uses the local rendered body position or the opponent's buffered position, and returns physical positions outside the drawing phase.

An explicit registry also reanchors stored melee records in ten helper families, including mouse jabs, saber, oar/light/tap, cleave, gopher claw, hammer, robot jab, tail slap, ninja cuts and mantis slashes. Several old flash records lacked owner IDs; the server update supplies them rather than guessing ownership when two players use the same hero. Character-bound animation ages progress between snapshots; remote attached records use buffered state age. Mouse jabs therefore follow the rendered body in mini mode while their animation advances between network updates.

Echo attacks, memories, mines, fields, travelling projectiles and fixed impact points keep their authored world-space locations. This does not move hitboxes or change damage. Main-game scenes keep their existing lookup behavior because the drawing context/hook belongs to this separate network arena.

## Networking changes and tradeoffs

Playback previously changed speed in response to raw snapshot-buffer occupancy, which rises and falls with every packet. The revised clock accounts for elapsed time since arrival, uses a drift dead band, and bounds rate adjustment to 0.95–1.05. A 64-snapshot arrival window chooses a target buffer between 100 and 180 ms, increasing for observed jitter and gradually returning toward 100 ms when conditions settle. All buffered players, shots and Tornado effects retain the same clock. This can add up to 80 ms of remote visual delay under jitter; it does not speed up the network or change the physics tick rate.

The client snapshot decode loop now has a soft 2.5 ms work budget per frame, plus the existing packet cap. A single packet and final state application can exceed that budget. Reliable events/inputs are retained; queued packets continue next frame. This reduces the risk of a recovery burst monopolizing a frame.

A lightweight gateway ping bypasses Godot authority processing. F8 records both gateway RTT and full authority RTT, arrival gaps, target buffer, playback rate, pending packets and decode-budget yields. Both RTTs still include browser scheduling/transit. Their difference is diagnostic evidence, not an exact measurement of server CPU or proof of where a delay occurred. Local reports remain local until downloaded/shared.

On a deterministic ordered stream with recurring 120 ms arrival variation, the old client held 19 measured frames and the new one held zero, using the 180 ms cap. That is a synthetic trace result, not a classroom improvement claim. Large gaps can still empty the buffer. WebSocket transport is unchanged and this patch does not eliminate Internet latency or certify production multiplayer.

## Next classroom test

Start with two players using Little Menace: move and attack normally, then shrink and run while holding primary. The punches should stay attached. Repeat with another melee hero, then a three/four-player mixed roster. Check Phoenix jump and Tornado effects still look right. If there is a glitch, press F8 and send FX_T48_performance.json from two players in the SAME match if possible, noting which hero/action glitched. No new video is required unless the visual behavior is otherwise unclear.

The supplied T4.7 Phoenix report has 82 three-player samples: median 58 FPS, minimum 51, median RTT 66 ms, maximum 104 ms, maximum sampled state age 287 ms, two playback resets, and 83 movement corrections. The previous much larger gaps were not present in this run. Different test activity/duration prevents attributing that difference to code alone.

See NETWORK_T4_8_VALIDATION.md and NETWORK_T4_8_ROSTER_AUDIT.json for exact checks and limits. This guide supersedes older version guides. The main living-town/day-night branch remains separate.

Research reference: https://gafferongames.com/post/snapshot_interpolation/ describes buffering snapshots to handle arrival jitter and its latency tradeoff; the specific implementation and limits above are our own.
