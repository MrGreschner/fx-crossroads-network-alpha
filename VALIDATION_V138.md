# v138 validation

Validated with Godot 4.5.1 and Node locally.

- 15 focused v138 checks: local draft availability, old draft recovery, immediate Training play, shared settings, live canvas merges, unsent edit preservation, validation rejection, timed mining bars and test comparison. All passed.
- 51 room-service tests: existing multiplayer plus two-pencil pixel merges, independent fields, late join state, ownership, protocol isolation, hostile path rejection, PNG codec and large message fragmentation. All passed.
- Two separate native headless game instances connected through the real WebSocket service. Both observed combined drawing in the shared model and still-open pixel canvas without Save image. Both exited successfully.
- Regression suites passed: v131 polish (96), v137 music/BandLab (35), v136 media/audio (38), v134 commerce (43), v130 classroom examples (44), v124 profile ZIP (12).
- Native rendered previews inspected at 1280 × 720: Pixel Studio with live toolbar, Idle Mining with visible construction progress, Design Detective comparison.
- All 80 official heroes retained. ZIP CRC and full extraction checked before delivery.

This is editable source. Web/Windows export templates are not installed in this environment, so final exported builds and two school browsers require the classroom checks in DEPLOY_V138.md. No deployment was performed.
