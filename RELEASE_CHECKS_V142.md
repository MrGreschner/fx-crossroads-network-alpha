# v142 release checks

Validated with Godot 4.5.1 on Linux.

- 82 new assertions: three sample portfolios, submitted/partial work, example grading isolation, business calculations and report validation, rolling damage expiry and thresholds, portable-profile validation, and public/private/custom lobby metadata.
- Real teacher/student WebSocket integration: 5 checks for opening a room, automatic Unicode portfolio upload, saved class records, returned feedback and matching-submission acceptance.
- Room service: all 67 Node tests pass. Service files and game protocol are unchanged from v141.
- 709 Godot assertions passed across the new and regression suites.
- Regression coverage: Student/Teacher unlocks and privacy, IPO programming, custom heroes and minions, live partner drawing, music and audio, timed Market, idle Mine, cosmetics, Studio labs, classroom examples and UI.
- Native rendered previews inspected: teacher examples and outcome review, unfinished work, all three business screens, and all eight lobby crowns. Corrected cramped opportunity fields and adjusted crown size/placement to fit the lobby.
- Editable archive checked for CRC, complete extraction and retained v141 files. All 80 official hero definitions, official artwork and realm content match v141 byte-for-byte.
- Fresh extracted project imported and launched headlessly.

Limits: no Web/Windows export templates are installed in this environment, so this release contains editable source. It does not claim validation on student browsers, mobile devices or a native Windows export. Lobby transport tests use simulated game channels; the separate class-room integration uses actual local WebSockets. Use the post-export checks in DEPLOY_V142.md on your devices.
