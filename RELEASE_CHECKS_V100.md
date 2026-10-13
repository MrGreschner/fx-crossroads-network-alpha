# v100 validation

Godot 4.5.1:

- New v100_performance.gd passed: 800 collision comparisons against full scans (negative coordinates, large radii and padding), 500 tree-index comparisons, retained terrain reuse, 48-chunk bound, menu hiding, region invalidation, correct tile textures, multiplayer cached tile equivalence and arena-map invalidation.
- v99_polish, v98_heroes, v97_refinements and v90_combat passed. The wall/fright, wall/rush and Hogtie regressions caught missing obstacle-index invalidation; automatic rebuilding after additions/removals corrected it, and both suites passed on rerun.
- Native screenshots inspected: plaza, river/forest, pond, southern garden, training and main menu. No missing terrain, script exceptions or incorrect drawing order in that run.
- Identical native town drawing benchmark: mean 2.550 → 1.110 ms; p95 3.340 → 1.335 ms. Warmed drawing-script samples only, not whole-frame or browser FPS.
- Simulation smoke runs (100 frames each) covered town, training, Grove and Sunfield, including walking and active enemies. No script errors in those runs.
- Room-service files compared byte-for-byte with v99: unchanged. Protocol remains 26.

Some existing headless combat suites print one retained-resource/ObjectDB warning at shutdown; their assertions pass and no gameplay script exception occurred. Physical school PCs, browser WebGL performance and live classroom multiplayer still require deployment testing. No Web/Windows export templates are installed here; this deliverable is editable source and export instructions, not a precompiled build.
