# v128 — Create opponents and teach their decisions

Crossroads Studio now includes Hero Workshop, Ability Lab, Behaviour Lab and Enemy Lab. The official 80-hero roster and its attacks are unchanged.

- Character Hall: Studio is in the header; Custom heroes is beside the filters.
- Charge controls: improve damage, size, reach, projectile speed/count, healing or knockback; choose a full-charge status separately.
- Behaviour Lab: editable bounded decisions, distance/health conditions, if/elif/else and loops. Enemy movement includes chase, retreat, orbit, hold and patrol. Ability behaviours select flight, targeting and impact modes.
- Enemy Lab: artwork in four poses, health/speed/body size, two configurable attacks, saved custom abilities and custom decision code. Draw pixels or upload PNGs.
- Battle Test: fight one to four designed enemies with the Workshop hero or practice melee/ranged heroes. Save damage, incoming damage, elapsed time and outcome as test evidence. No player progression is awarded.
- Advanced code: Level 1 is editable instruction code. Level 2 shows the actual methods, arrays, targeting and projectile physics. Level 3 shows the runtime's classes and object references. Levels 2–3 are read-only; they explain how the safe instruction layer runs. Arbitrary GDScript is not executed.
- Share separate .hero.json, .ability.json, .behavior.json and .enemy.json projects. Player ZIP backups include all four saved libraries plus unfinished hero, enemy and behaviour drafts.
- New game explicitly warns that local custom creations will be cleared. Download a backup first.
- Added vertical padding for main-menu labels/buttons; Studio and Mistglass Spire are spaced farther apart.

## Deploy
1. Extract this source ZIP into a new folder and open `FX_Crossroads/project.godot` with Godot 4.5.1.
2. Allow asset import to finish. Run the project and test the four Studio labs.
3. Export **Web** using the existing preset. ZIP the exported files with `index.html` at the ZIP root; upload that Web ZIP to itch.io. The source ZIP is not the playable Web upload.
4. Re-export Windows if you offer the downloadable game, then replace that download on itch.io.
5. No Render deployment, server files, build command or environment changes are required for v128.

Custom enemies run in the Studio sandbox, not existing realms. Custom creations remain local single-player work; sharing uses downloaded project files. Runtime code examples are packaged as JSON resources so the code lessons also work in exported builds.
