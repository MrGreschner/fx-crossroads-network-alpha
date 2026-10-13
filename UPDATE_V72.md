# v72 — Stability first

## Reduced avoidable work

- Browser School performance mode defaults ON: 30 FPS and viewport rendering at the game’s logical resolution, limiting high-DPI pixel rendering. Normal mode uses 60 FPS and canvas-item scaling. Toggle it under Profile.
- Cosmetic effect, trail and floating damage queues have bounded budgets. Core damaging projectiles, enemies, combat statuses and AI are not dropped.
- Multiplayer state updates are prepared only when a direct guest link is open. Solo modes do not build snapshots for nobody.
- A world/lobby packet is serialized once per broadcast instead of once for every guest. World updates use 10 Hz instead of about 12 Hz; interpolation remains enabled.
- If a guest’s outgoing queue exceeds 512 KiB, replaceable active-state updates are skipped until it drains. Final results and gameplay command messages are not skipped by this rule. Diagnostic counters record queue sizes, deferrals and send errors.
- Starting another match clears unsent cosmetic events and short-lived feedback queues.

## Diagnostics

Profile → **Download diagnostic report** exports a local JSON report. It does not upload anything. Samples include FPS, Godot static memory, render/video-memory monitors where available, object/effect/enemy/projectile counts, scene/mode/floor/wave and packet queue counters. These monitors are clues, not a complete measurement of browser-process RAM.

Native reports include a bounded engine-log tail. Browser startup installs bounded JavaScript/Godot-console error capture, stores recent information locally and listens for WebGL context loss. A graphics-loss panel offers a report-download button even if game input no longer works. A complete browser/tab crash may prevent that panel from appearing; the most recent saved sample may still survive.

An interrupted previous session is explicitly described as a refresh, close OR crash, not treated as proof of a crash. Normal session end is recorded where Godot receives shutdown. Download your profile separately for progress backup; diagnostics are not a player-profile backup.

## Windows edition setup

A Windows Desktop export preset, **BUILD_WINDOWS.cmd**, PowerShell dependency/export script, native WebRTC probe and manual GitHub Actions build workflow are included. They prepare native multiplayer using the official Godot WebRTC extension, not a new gameplay server. The existing Render signalling service is unchanged.

**No compiled Windows executable is included.** GitHub binary downloads were blocked in this execution environment. The script must run on your Windows PC or GitHub Actions to create the playable ZIP. The Windows script and native extension could not be executed here and are not represented as verified Windows multiplayer.

## Validation completed here

Godot tests cover cosmetic caps, logical-resolution/30 FPS configuration, preserving enemies, solo-link detection, snapshot queue rules, clean match resets, diagnostic JSON and export-preset parsing. Browser diagnostics were tested with a simulated JS environment for sample persistence, context-loss prompts and bounded errors. Existing player-card, lobby/team, combat replication and profile restoration tests pass.

Native Windows export and Windows/browser interoperability remain unverified. Reproduce the school-PC crash with the new diagnostic build before claiming its underlying cause is resolved. Driver/browser failures can still occur; these changes reduce pressure and provide evidence for the next fix.
