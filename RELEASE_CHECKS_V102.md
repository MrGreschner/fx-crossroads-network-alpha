# v102 validation

- New Godot regression: 0 failures. Covers bounded interpolation/extrapolation, teleport resets, stale packet rejection, motion routing, reliable events/results, congestion, metadata changes, compression, fragment reordering/duplication/loss/bounds, local correction, attack acknowledgements, Tova timing and Clockwork movement.
- Existing v101 stability, v100 performance, v97 refinements, v90 combat and v76 recovery tests: 0 failures.
- Room service: all 32 Node tests passed, including WebSocket resume/spectator tests and protocol-27 isolation.
- Local software-OpenGL comparison, 140 sampled frames per variant: arena drawing-script mean 1288 µs without retained ground versus 852 µs with it (about 34% lower); p95 1667 versus 1131 µs. This measures drawing-script work, not total frame rate or school hardware performance.
- Representative snapshot: full JSON 5298 bytes, streamlined state 5151, compressed wire state approximately 2577 (metadata/events sent separately).
- Headless and local rendering tests are not sustained browser-to-browser WebRTC matches. School GPU-loss reproduction, real wireless latency and native/Web cross-play remain deployment validation steps. Export templates are unavailable in this workspace, so delivery is editable source.
