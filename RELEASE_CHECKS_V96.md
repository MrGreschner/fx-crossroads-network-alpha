# v96 validation

Checked with Godot 4.5.1.

- `tests/v96_polish.gd`: passed. Four complete, distinct six-card gallery sets per side; valid artwork; hidden-animation idle behavior; short lore and passive summary for every hero; four collapsed abilities visible without scrolling for all 72 heroes at the standard viewport; independent expand/collapse; Patch lore dialog; visible names for revealed encounters and hidden names for unknown ones; cached forest density, camp clearance and traversable trails.
- `tests/v90_routes.gd`: passed with every town upgrade enabled, including quest entry and Chimehouse.
- `tests/v93_menu.gd`, `tests/v94_polish.gd`: passed title/pause, lobby/team and town-route assertions.
- `tests/v95_maintenance.gd`: all assertions passed, preserving numbering, favourite icons, caching, settings and Gate Defence pressure. Its extended combat shutdown emitted the previously observed one-resource headless warning.
- Rendered and inspected all four gallery sets, collapsed/expanded Character Hall, forest/camp and named encounter portraits. No script exceptions in the final rendering run.

The isolated local town drawing-script benchmark averaged 2.093 ms (p95 2.594 ms), versus 2.196 ms (p95 2.686 ms) for v95 on the same camera path. These are local software-renderer CPU timings, not classroom FPS measurements.

Animation has a 30-Hz redraw limit independent of the selected device FPS cap. Caption layout, tree positions and existing terrain tiles are cached; no assets load per animation frame. This is not a guarantee of smooth performance on every school computer.

No physical phone or live classroom multiplayer match was tested. Re-export and smoke-test on your usual devices before replacing the public build. Service protocol remains 26; see DEPLOY_V96.md.
