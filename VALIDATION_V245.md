# V245 verification

**4,549 source checks and 4,549 exported-runtime checks passed, zero failures.**

734 item/atlas/coverage and actual purchase/refund checks; 606 protected streets; 2,938 protected homes/vegetation; 233 protected shops; 15 prepared-item handoff; 23 healing/consumption ownership checks. Every suite was run against both source and the final production resources, through a separate QA-only pack that adds test entry points.

15,389 original V244 files are unchanged, including 11,830 original art/scene/content files. 7,469 original functions are byte-identical. Changes to original functions are limited to named rendering/UI methods. All gameplay catalogues, prices, effects, recipes, unlocks, save formats, navigation and original state declarations remain unchanged. Evidence: `qa/evidence245/source_preservation.json`.

27 inspected native packaged-runtime captures cover shop tabs, food, inventory, gear/cosmetics, all relics, all nine selected live rod appearances by day/night and narrow toolbar geometry. 156.0.8078.73 Chromium/WebGL2 captured eleven review states and booted the unmodified production build through its opening to the normal main menu. No uncaught browser page errors or in-session GDScript errors in final runs. Fresh Server Update import and authority compile passed. Web JavaScript syntax checks also passed.

## Static render comparison

Godot 4.5.1 Compatibility, Mesa llvmpipe software rendering, 1280×720. Six paired static views: 20 warm-up frames plus 40 samples. Baseline and candidate measured sequentially after other rendering jobs finished; the game main simulation is paused and UI continues. CPU monitor figures do not predict physical school hardware.

| View | V244 draw calls | V245 draw calls | V244 CPU median ms | V245 CPU median ms |
|---|---:|---:|---:|---:|
| Equipped toolbar / Day | 190 | 195 | 25.18 | 28.82 |
| Supply vendor / Day | 207 | 207 | 42.45 | 29.85 |
| 21 relic gallery / Day | 368 | 196 | 108.24 | 26.15 |
| Equipped toolbar / Night | 237 | 242 | 68.49 | 24.43 |
| Supply vendor / Night | 254 | 254 | 40.55 | 23.37 |
| 21 relic gallery / Night | 415 | 243 | 37.62 | 24.16 |

The shared atlas is exactly 8,388,608 decoded bytes. No new shaders, particles or per-frame texture construction. See raw profile JSON for total texture memory; the CPU results are diagnostic.

## Limits

No deployment, physical school-device benchmark or live account/multiplayer connectivity test. Local static previews have no live account backend. Native QA inherits the V244 ObjectDB/three-resource cleanup warning at process shutdown, after passing checks.

Production PCK SHA-256: `98c93a07fe88b44bd89aaabdb6646a8407244790a5cc8b60a6e9e6826f2f620c`.
