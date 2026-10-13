# v94 validation

Checked locally using Godot 4.5.1.

- `tests/v94_polish.gd`: passed. River tree clearance, fence extent, east quest entrance, both walking routes, click-based team previews, side counts and avatar placement, preference surviving connection, host inheriting and changing sides, blocking unhosted/unbalanced starts, Battlegrounds team preview and non-overlapping co-op selectors.
- `tests/v90_routes.gd`: passed with all town upgrades enabled, including the relocated quest entrance, Chimehouse and northern Battlegrounds access.
- `tests/v88_party.gd`: all party/leaderboard assertions passed. Its legacy headless test reports one retained resource during shutdown; the v94 test exits cleanly.
- Rendered and inspected river/fence, bridge/forest fork, an empty-room blue-team preview and co-op selection. No rendering script exception; local software-renderer V-Sync warning only.

No live multiplayer classroom session or physical mobile device was tested. Before public release, export the Web build, verify touch team selection and run one actual multiplayer match. This update is editable source; no account deployment was performed. See DEPLOY_V94.md. Service protocol remains 26.
