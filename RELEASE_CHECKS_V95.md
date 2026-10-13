# v95 checks

Godot 4.5.1 local checks:

- Import/editor scan: no script parse errors.
- `tests/v95_maintenance.gd`: consecutive numbers for all 72 heroes; Harbor Bell / Polarity positions; vector favourite icons; terrain cache equivalence and invalidation; patrol position equivalence; idle-save deduplication; Options and persisted settings; invalid FPS rejection; immediate opening wave and eight-second follow-up; far-road entrances; scaled bounded wave counts; guards-only pressure simulation.
- `tests/v87_menus.gd`: menu/input, profile restrictions, number search, level cards and owl checks. Updated the old numbering expectation to the requested current roster order.
- `tests/v93_menu.gd`, `tests/v94_polish.gd`, `tests/v90_routes.gd`: title/pause behavior, town routes, lobby team choice and layout checks.
- `tests/v80_north_gate.gd`, `tests/v83_gate.gd`: spawn/checkpoint behavior, guard speed, rival scaling and skills. The timing test reads the new configured second-wave interval.
- Rendered and inspected the main menu, Options, Character Hall stars and top profile shortcut.

Town drawing benchmark, same 150-frame camera path at 1280×720 using the local software renderer: mean script draw time decreased from 2.724 ms to 2.196 ms (about 19%); p95 decreased from 3.136 ms to 2.686 ms. This measures drawing-script CPU time, not overall FPS or a school computer's GPU performance.

In a 120-second solo simulation with the hero not attacking, enemies remained and all three outposts were lost. This verifies the guards cannot win the opening by themselves; human playtesting should determine whether the pressure needs further tuning.

Some extended combat headless runs emitted one retained-resource warning at shutdown despite all assertions passing; the verbose repeat of the v95 test exited cleanly. No live classroom multiplayer session, Web export runtime or physical phone was tested here. Browser WebGL2 support remains required. See DEPLOY_V95.md for export and smoke-test steps.
