# v105 — Temporary Game Dev mode

## Enter testing
Talk to Elder Ram, choose Something else and type **gameDev** exactly. When he asks **Password?**, enter **R4ms** exactly. The old teacher trigger and password no longer activate testing.

A gold/orange outline surrounds the screen, with **GAME DEV • TEMPORARY / NO PROGRESS** at the top. The outline remains visible in town, realms, multiplayer and menus.

Testing unlocks both mastery techniques, full critical mastery, six tuning points for every hero, all town projects/upgrades and journey cosmetics. You can select and try techniques rather than permanently earning them.

## Protecting real profiles
- Normal progress is saved before testing begins.
- During Game Dev mode, profile changes are held in memory only. No temporary profile progress is written to disk/browser storage.
- Profile download, upload, rename saving, new-player replacement and clearing are blocked while testing. Internal profile bundling also returns no testing profile.
- Mastery progress, profile badges, arena records, realm speedrun records and Descent best-floor files cannot be earned/saved for the testing player. Quest, food and cosmetic testing changes remain temporary.
- Dev mode remains active when moving between town and multiplayer scenes, but never survives a browser refresh, restart or fresh application process.
- In **Profile**, use **Exit game Dev mode • restore my profile**. This ends the current testing session and returns to the main menu/town with your real profile. Temporary changes are discarded.
- Frame/crash diagnostics and device settings remain available; they are not player progression.

The existing internal `teacher` field is retained as a compatibility flag used by reward guards. The new session is never persisted as a teacher/dev account. Old persisted teacher flags do not automatically grant Game Dev access in this version.

## Update
All v104/v103 changes and 74 heroes remain. Export a fresh Web build for itch.io. **No Render changes are required if protocol 28 from v103 is already deployed.** Otherwise follow DEPLOY_V103.md first.

## Validation
Local Godot checks cover the exact trigger/password, wrong/old credentials, all mastery/town unlocks, visible testing border, blocked import/export, memory-only writes/deletes, no result/achievement credit, scene-switch persistence, refresh restoration and explicit Exit restoration. Normal save-file bytes were compared before and after testing. v104 replay/countdown and v103 Descent/realm checks passed. Native software-OpenGL border/profile previews were inspected. No compiled Web/Windows export or live browser multiplayer test is included.
