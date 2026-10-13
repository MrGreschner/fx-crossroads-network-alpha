# v101 checks
- Godot 4.5.1 import: no parse errors.
- New v101 stability regression: passed, including authoritative departure while RTC still reports open; channel/peer closure; self-kick prevention; 30-second unfinished join expiry; host-only button; untrusted kick rejection; complete guest teardown.
- Existing v76 recovery and v100 terrain/collision performance regressions: passed.
- Node room-service suite: all 31 tests passed, including real WebSocket adapter tests and new host authorization, seat release, signaling rejection and expired removed-session tests.
- Diagnostic JavaScript syntax: passed.
- Native OpenGL lobby screenshot reviewed: Kick controls fit beside guests, including a connecting placeholder; spectator host excluded.
- Web/Windows export templates are not installed here. This release is editable source, not a compiled web or Windows build. School-browser GPU-loss reproduction and sustained live WebRTC matches remain deployment validation steps.
