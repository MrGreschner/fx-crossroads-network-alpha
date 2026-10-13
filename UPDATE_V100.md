# v100 — School-PC performance pass

74 heroes remain unlocked. This is a performance update to v99, with gameplay rules and room protocol 26 preserved.

## Town and realm rendering

- Base terrain now uses retained 512-pixel chunks. Ground drawing commands are created when a chunk is first needed, then moved smoothly with the camera. This applies to town, training and solo realms.
- The cache holds at most 48 chunks, frees old chunks as you explore, and invalidates when switching regions. It shares existing textures; it does not allocate a huge town-sized render texture.
- Off-screen pond animation, lookout, campfire, mine, gardens, Chimehouse, postal courtyard, residents, furniture and labels are skipped. Viewport margins retain partially visible objects.
- Visible scenery, NPC animation, river flow and hero movement remain. This pass does not remove enemy warnings or change damage, collision radii, AI or player speed.

## Gameplay work

- Town tree collision checks use nearby spatial buckets instead of scanning every trunk for every movement step.
- Solo projectile and dash path checks use an obstacle index with exact-radius collision checks. Obstacle additions/removals rebuild the index automatically; explicit build_scenery() remains required when moving an existing static obstacle in place.
- Multiplayer terrain remembers terrain/path selection per tile, removing repeated polygon checks while standing or fighting in the same area. It resets on floor/map changes and is bounded at 4,096 entries. Spectator-size tiles are separate entries.

## Diagnostics

Reports now include simulation/physics milliseconds, rendered object count, viewport size and retained terrain chunk count, with the correct v100 version label. Main menu → Options retains the school-performance toggle, FPS limits, sound and report-download controls. Browser builds still default to school mode and 30 FPS; existing device preferences remain.

## Measured result and limits

Identical local native drawing-script benchmark, moving across the town at 1280×720 (281 samples after warm-up):

| Measure | v99 | v100 |
| --- | ---: | ---: |
| Mean drawing-script time | 2.550 ms | 1.110 ms |
| 95th percentile | 3.340 ms | 1.335 ms |

Mean town drawing-script work fell about 56%. This is **not a claim of 56% higher browser FPS**: browser/GPU/computer settings also affect performance. Measurement used Godot 4.5.1 and Mesa llvmpipe on this machine, not the school PC. Visual checks covered town plaza, river/forest, pond, garden, training and main menu. Simulation smoke runs covered town, training, Whispering Grove and Sunfield.

## Hosting versus downloading

A different web host mainly improves initial download time and availability. Our game simulation and graphics still run on each player's computer. Moving the room service does not move the host player's gameplay simulation onto that server.

The Windows edition removes the WebAssembly/WebGL browser path and can help school PCs, but performance still depends on their hardware and driver configuration. It retains the same online room service and can play with browser users. The ZIP supplied here is editable source, not a ready-to-run Windows edition; use the included Windows export script/preset to produce one.

Do not enable Web threads as an untested quick fix: Godot's threaded Web export requires cross-origin isolation and has additional browser/store compatibility requirements. Keep the existing single-thread Web preset for this deployment.

For the classroom rollout, first export and test this version on the actual affected PC, with School performance ON and 30 FPS. Test town walking and one busy match. If it is still slow, download a report while it is happening; compare the same session with the exported Windows edition if school policy allows.
