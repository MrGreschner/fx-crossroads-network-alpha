# V247 verification

18,852 checks passed in the source project and again against the packaged resource set (37,704 total). Suites cover crops and weekly NPC schedules, portal frame integrity, path masks, cached water, item/relic art, street and bridge access, shops, carried equipment and KO healing. All 11,421 sampled walking positions match the independently captured V246 baseline.

32 native preview images include main square, pond/grass, river bridge, marina and Wayfarer's Court in daytime and nighttime; all three actual portal tabs; compact portrait/landscape layouts; sixteen portal animation phases; and locked routes. Chromium rendered 18 review views and the ordinary production startup/menu, with WebGL2 and no script errors. The narrow portrait menu retains the game's existing logical-width scaling, so desktop or landscape remains more readable.

Dedicated server import and compile checks passed. Every changed production resource matches between source, Web and Server Update; every unrelated V246 Web resource remains byte-identical. Release ZIPs are checked for CRC errors and duplicate members. The V247 review fixture is separate from the production Web PCK. The normal browser startup reached the main menu; requests to live services were unavailable in the local environment, so those services are not included in the browser pass.

Native Godot reports its inherited ObjectDB/three-resources shutdown warning in isolated QA scenes. No script errors are accepted. No deployment, physical school-PC test or live-account/backend multiplayer test was performed.

Measured locally with Godot 4.5.1 Compatibility, Mesa llvmpipe software graphics at 1280×720. Both builds use the same isolated scene, 40 warm-up and 80 measured frames per view. Medians below. CPU timings on shared software graphics are noisy and are not school-computer FPS guarantees. No physical school computer or live multiplayer backend was tested.

| View | V246 draw calls | V247 draw calls | V246 process ms | V247 process ms |
|---|---:|---:|---:|---:|
| Main_Square Day | 320 | 257 | 37.04 | 44.19 |
| Pond Day | 257 | 194 | 34.59 | 40.3 |
| River Day | 158 | 159 | 175.72 | 63.64 |
| Marina Day | 154 | 158 | 30.53 | 90.54 |
| Wayfarers Day | 215 | 216 | 24.7 | 144.8 |
| Portal_Menu Day | 521 | 345 | 49.97 | 78.25 |
| Main_Square Night | 413 | 347 | 32.56 | 71.15 |
| Pond Night | 328 | 265 | 77.15 | 78.12 |
| River Night | 209 | 210 | 95.02 | 89.0 |
| Marina Night | 171 | 175 | 86.22 | 82.09 |
| Wayfarers Night | 253 | 254 | 260.46 | 53.19 |
| Portal_Menu Night | 611 | 435 | 257.15 | 176.61 |

Peak sampled texture memory: V246 151.92 MiB; V247 161.05 MiB; change +9.12 MiB.
