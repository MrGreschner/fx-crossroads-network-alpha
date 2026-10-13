# v86 release checks

- `python3 tools/release_audit.py`: 60 heroes, 0 errors.
- Godot 4.5.1 headless editor import: no script parse/load errors.
- Godot scripts: v86_release, v86_multiplayer, v85_heroes, v85_coop, v84_update, v84_coop, v83_gate, v81_arena: zero assertion failures.
- `npm test` in room_service: 23 passing, 0 failing, including real WebSocket adapter, reconnect, spectator, capacity and version-isolation checks.
- Native rendered hero hall, support filter and new ability previews inspected.

Some headless test shutdowns retain the existing ObjectDB/resource-cleanup warning. No gameplay script failures occurred during these runs. Physical mobile and live hosted deployment are not covered by these checks. Source is not a pre-exported Web or Windows build.
