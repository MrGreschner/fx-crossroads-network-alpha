# Crossroads V231 — Gate Defence, AI heroes and Battlegrounds art

- Fixed both missed north-gate sentries: their landmark render path now uses the same current town guard art as the patrols.
- Refreshed all three Gate Defence guard roles (melee, archer, area caster), all seven dedicated AI heroes, both faction versions of all eleven Battlegrounds troop types, and the Tollbreaker boss. 33 designs / 132 idle, walk-A, walk-B and attack poses.
- Preserved species, signature equipment, faction palettes and existing NPC/boss size proportions. Neutral front-facing poses; Battlegrounds sprites no longer mirror their equipment according to travel direction. Original attack simulation, timings, damage, costs and army rules remain.
- Recruited guards now show actual idle/movement and an attack pose. A small cosmetic timestamp travels with existing guard snapshots. Gate rivals and Tollbreaker load all four new poses, including attack tells.
- Removed the orange danger circles and exclamation badges in Gate Defence. Cave Descent suppression remains. Other realms retain their existing warning visuals; healing areas, damage effects and strategic meeting markers remain.
- Removed the main-menu Bramble special override that substituted the unused leafy minion artwork. The menu now uses the actual current realm enemy.
- Corrected the intro's six Ram/Bramble walk frames using cached lower-limb cutout articulation on the original cinematic artwork. Upper body/head pixels stay fixed while opposite feet change depth and stride. Same selected PNGs are shipped in native and browser versions; browser asset URLs now carry a version query to prevent stale footsteps after updating. Camera, story timing, portal activation, scene artwork and transparent inactive arch are unchanged.

## Efficiency and validation

One cached 320×2640 atlas supplies the new units. No per-frame image manipulation, SVG rasterization or new render targets. Gameplay AI, army population limits, collision, records, progression and backend service/configuration are preserved.

675 focused checks passed: 132 poses, cached loading, transparency, distinct steps, size bounds, AI/rival loaders, mode-specific warning rules, guard snapshot timestamp and actual Bramble menu source. 4,574 shared hero/stat/authority/Cave checks and 271 Battlegrounds simulation/ordering/network checks also passed. 44 browser portal checks also passed for day, night and reduced motion. Native sentries, idle/attack/motion galleries inspected. Existing test-harness ObjectDB/resource shutdown warnings remain; zero failed assertions. Browser gameplay and school-device performance remain for manual testing.

Selected built-in ImageGen source sheets and prompts are included in the editable source under assets/unit231 and tools/unit231_prompts.json. See ART_SOURCES_V231.md. The unused cinematic ImageGen draft is not selected; final footsteps reuse original art through the repeatable cutout-animation tool.

## Upload

Deploy Server Update first, retaining existing environment settings and persistent database storage. Then replace itch.io Web files. Editable is the matching Godot project. Nothing deployed automatically.
