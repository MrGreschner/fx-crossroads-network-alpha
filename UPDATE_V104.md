# v104 — Replay and visible match countdown

- Realm results now include **Play again**. It starts the same realm with the same selected hero directly, resetting run-level health, level, cooldowns and combat statistics. It does not award the previous result twice or refund consumed food/items. A fresh attempt starts with the normal 100 gold. This button also appears after a solo realm victory. Multiplayer retains its Return to party flow.
- The five-second multiplayer start countdown now appears in a large centred panel, **above the lobby and world HUD**. It says MATCH STARTING, uses large yellow digits, then changes to red for 3, 2, 1. It hides when the countdown reaches zero. It does not capture mouse/touch input or change match timing.
- All v103 optimizations and features remain included; 74 heroes.

## Installation
Extract and open FX_Crossroads/project.godot. Export a fresh Web build and replace the playable itch.io upload. This ZIP contains editable source, not compiled browser files.

**No additional Render redeploy is required if v103's protocol-28 room service is already live.** If Render still runs v102/protocol 27, follow DEPLOY_V103.md first. Server files and multiplayer protocol are unchanged by v104.

## Validation
Godot 4.5.1 checks passed for result-button availability, same-realm/same-hero replay, fresh health/level/statistics, no duplicate result record, countdown layer visibility, yellow-to-red transition and hiding at zero. Native software-OpenGL previews checked the results and countdown panels. Compiled Web/Windows exports and live school-browser WebRTC were not tested here.
