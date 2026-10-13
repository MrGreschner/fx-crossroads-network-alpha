# v103 validation

Tested locally with Godot 4.5.1 and Node's room-service suite.

- v103 journey checks: zero failures. Town aura gates, boss-only floors 5/10/15/20/30/40, floor-30 movement/four attack types, post-10 reward queue, capped cooldown choices, healing-gem credit rules, portable deepest-floor record, retained geometry and new realm enemies.
- v103 lobby checks: zero failures. Five arena maps, eight spawn positions each, forced tree obstruction, adding/removing bots with two humans, spectator seat transitions and Wick balance data.
- Existing checks: v102 smoothing, v101 stability, v100 performance, v97 refinements, v90 combat, v76 recovery, v67 combat and v70 player-card checks passed. The old v70 fixture was brought in line with the already-existing 10,000/85,000 mastery requirements. v98 fright expectations now match its explicit balance change.
- Room-service suite: 34 tests passed, zero failures, including protocol isolation, waiting-room changes, occupied capacity protection and unchanged active-match settings.
- Diagnostics JavaScript syntax checked; Godot editor import showed no script parse errors.
- Native software-OpenGL visual checks: Honeyglass retained floors, Options, diagnostics panel, post-10 upgrade cards, floor-30 warning/boss and town.

## Honeyglass component comparison
The same local script measured the original v102 and v103 implementations under Mesa llvmpipe. Repeated floor-drawing script time over 90 sampled frames was about **11.09ms → 0.42ms**; 10,000 deterministic collision queries were **294ms → 29ms**. The retained layer does initial drawing once. These measurements isolate repeated script/geometry work; they are not whole-game GPU/frame timings or school-PC/browser FPS.

## Limits
No matching Web/Windows export templates were available here, so no compiled export is delivered. Live itch.io WebRTC, school GPU context-loss recovery and low-end mobile performance need deployment testing. Some older headless tests emit existing resource-at-shutdown warnings despite passing their assertions. No remote server was deployed or changed.
