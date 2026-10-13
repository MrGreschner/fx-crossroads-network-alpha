# v130 validation

- Godot 4.5.1 focused Game Dev / comparison checks: 30 passed.
- Godot classroom and examples checks: no failures. All 20 portable examples validate, including four artwork poses for hero and enemy examples.
- Previous v129 gameplay regression checks: no failures.
- Room service Node tests: 44 passed, including actual WebSocket teacher + 31 student clients, capacity rejection and disconnect cleanup.
- Live Godot viewport capture reached a WebSocket viewer as a 1024×576 JPEG (74,200 base64 bytes).
- Visual review: Game Dev panel, comparison window, example interfaces, classroom lobby and student viewer.
- Source ZIP is checked for CRC integrity, full extraction and retention of previous source files. All 80 official hero data/art files are retained unchanged.

Limitations: Web/Windows export templates are not installed in this workspace, so rebuild and validate those exports locally. Classroom demonstrations are intentionally limited to up to 2 FPS. Validate school network bandwidth and several real student machines before running a 31-student lesson. Test mode is a local educational tool, not secure account authorization.
