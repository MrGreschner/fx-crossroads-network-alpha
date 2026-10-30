# Crossroads V253 — Whispering Grove

Complete environment artwork update based on authoritative V252. No deployment performed.

New matte woodland floor and earth path textures, softened path margins, a gnarled broadleaf tree canopy, ferns, mossy fallen roots/logs and flowering understory. Built-in image generation produced six source assets; paths have 16 precomputed alpha-edge variants. The larger decorative tree canopy retains each original trunk anchor and collision radius. Trees remain behind actors for combat readability. Only Whispering Grove uses these replacements, in solo and co-op.

All authored scenes, region JSON, encounters, portals/merchant positions, routes, collision circles, combat rules, rewards, fishing catalogue and V252 aquatic artwork remain unchanged. There is no authored Grove fishing spot; no new pool or fishing interaction was added.

Terrain uses existing retained 512px chunks with a 48-chunk bound. Static textures are decoded once and reused; up to 22 small textures, approximately 1.43 MiB RGBA payload plus driver overhead. No new shader, particle simulation, per-frame image readback or physics work. Edge masks add retained commands along paths; co-op retains terrain span merging. Actual school hardware was not benchmarked.

Verification: 44,529 passing checks: Grove 92, aquatic 35637, Descent 4350, marina/UI 4450. Grove checks exercise camera traversal, bounded/stationary caches, unchanged 127 collision obstacles, solo/co-op terrain setup and server script compilation. Six native and six WebGL2 previews, plus the normal production Web menu, passed. Low_Light previews use a visibility stress-test tint; this update does not add a new realm day/night mechanic. Preview enemies are removed only in the QA fixture so scenery is visible.

Every changed production resource was byte-compared across Editable, Web PCK and Server Update. Unchanged Web pack resources were preserved. Isolated native QA retains baseline ObjectDB/three-resource shutdown warnings; local browser startup can report unavailable external-service fetches. No live multiplayer backend or public host was tested or deployed.

Downloads: Web is the complete browser build; Server Update overlays the existing server while retaining its secrets/configuration and saved data; Editable opens standalone in Godot 4.5.1 after import. Update Server before Web. Previews contains all captures; Art Sources contains the six original painted PNGs and production specifications.

Reproduction: tools/release253 contains normalization, packaging and PCK tools. The preservation build requires matching V252 packages/extracted web252 and server252. Original full-resolution artwork remains outside runtime and Editable packages. All previous V252 files remain present; no historical media has been removed in this update.
