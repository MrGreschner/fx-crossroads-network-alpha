# V244 validation

## Preservation

Authoritative baseline: completed V243 Editable/Web/Server Update archives, recovered and CRC checked. 15,285 original files remain byte-identical, including 11,821 artwork, scene and content files. 7,280 original functions are byte-identical. Only the recorded renderer/setup functions change. Existing top-level state/constant declarations are unchanged except the version stamp. The four edited cache PNGs preserve every RGBA texel outside explicit replacement masks. Approved building, hero, home and vegetation illustration sources are unchanged.

The V243 and V244 contracts are exactly equal: **32,388 collision/entrance/tree/world/deck probes**, **315 resident schedule states**, and **288 guard/marina patrol states**. Roads, wall solids, every door/service point, tree roots, cargo rectangles, bridge/deck geometry, event definitions and routes are recorded. Both built and unbuilt states and both duplex entrances are covered. Dense samples cross both bridges and all marina fingers.

## Runtime checks

- Street artwork/cache/deck checks: 606 passed.
- Protected V243 homes/vegetation checks: 2,938 passed.
- Protected V242 shops checks under the V244 release stamp: 233 passed.
- Total: **3,777 passed** in the source/runtime suites and again against the packaged runtime; zero test failures.
- Actual Server Update directory: fresh editor import completed, followed by successful dedicated `network/server.gd` check-only compilation.
- Shared texture reuse, 29 atlas frames, four edited raw PNG cache pages actually loaded, bridge spans and rail anchors, available service approaches and release stamp checked.

## Visual review

**144 native 1280×720 captures** from the packaged runtime: forty town areas and twenty-four protected facades by day and night; earned Veteran Gate; unbuilt south/west/civic project states; weekly fruit stall, makers' fair and picnic; rain over the crossing; apple knock/drop, watered garden and three canopy phases. Review boards and full-sized originals are supplied. All four grand landmarks and the six V243 homes are included.

The review corrected older watermill/Mistglass Spire sign alignment, put the unchanged northern approach below the gate roof, retained the lookout's label, and replaced three remaining flat flower-island paintings with the accepted V243 seven-flower artwork. Street details were inspected in daytime and nighttime without introducing new light sources. Existing warm window masks, Starlace glints, willow lanterns, campfire timing and motion remain live.

**Browser:** Chromium 156.0.8078.73, headless shell, WebGL 2.0, 1280×720, local HTTP with cross-origin isolation. A separate QA pack containing byte-identical production resources rendered four acknowledged day/night bridge/notices views, checking atlas dimensions, build and clear approaches. Browser captures were inspected. The unmodified production HTML/PCK also booted to its normal main menu. No uncaught page errors were observed. Account-service fetch probes fail in the static preview because no deployed backend is running there; live account/multiplayer connectivity was not tested. This is browser rendering/boot coverage, not an online-service test.

## Native rendering measurements

Godot 4.5.1 stable, Compatibility renderer, Mesa llvmpipe software OpenGL. Same frozen 1280×720 fixture, twelve cameras, noon and 23:00 local time, earned projects enabled in the isolated fixture. Each view warms for 15 frames and samples 30 more. V243 and V244 run sequentially without other visual render jobs. CPU duration covers the game's draw callback including its normal HUD; renderer draw calls and texture storage are monitored separately. These are indicative native software-renderer measurements, not physical school-device frame rates.

| View | V243 draw ms | V244 draw ms | V244 p95 ms | V243 calls | V244 calls |
|---|---:|---:|---:|---:|---:|
| North gate — Day | 3.950 | 4.055 | 19.804 | 317 | 300 |
| Western fence — Day | 3.037 | 3.042 | 3.833 | 326 | 143 |
| Pond — Day | 4.197 | 4.136 | 6.650 | 432 | 367 |
| Civic square — Day | 4.252 | 4.036 | 5.082 | 381 | 361 |
| West campus — Day | 2.850 | 2.744 | 3.828 | 148 | 136 |
| Market — Day | 3.735 | 3.435 | 3.940 | 326 | 297 |
| Post — Day | 3.455 | 3.133 | 4.730 | 272 | 260 |
| Notices — Day | 3.571 | 3.569 | 5.443 | 280 | 264 |
| Main bridge — Day | 3.184 | 3.100 | 3.749 | 224 | 191 |
| South bridge — Day | 3.118 | 2.868 | 3.991 | 193 | 174 |
| Marina — Day | 3.005 | 2.776 | 3.445 | 174 | 165 |
| Woods — Day | 3.320 | 2.775 | 3.694 | 222 | 182 |
| North gate — Night | 4.118 | 4.420 | 5.483 | 385 | 368 |
| Western fence — Night | 3.587 | 3.059 | 5.830 | 359 | 176 |
| Pond — Night | 4.484 | 4.445 | 12.521 | 493 | 427 |
| Civic square — Night | 4.387 | 4.428 | 5.375 | 468 | 448 |
| West campus — Night | 2.849 | 2.905 | 5.258 | 170 | 158 |
| Market — Night | 3.768 | 3.666 | 4.351 | 397 | 368 |
| Post — Night | 3.594 | 3.850 | 6.777 | 298 | 286 |
| Notices — Night | 3.694 | 3.698 | 6.085 | 312 | 296 |
| Main bridge — Night | 3.584 | 3.304 | 4.262 | 270 | 237 |
| South bridge — Night | 3.189 | 2.994 | 3.481 | 212 | 197 |
| Marina — Night | 3.017 | 3.012 | 3.944 | 194 | 185 |
| Woods — Night | 3.630 | 3.482 | 4.758 | 266 | 226 |

Draw calls fall in all 24 views. The median of the per-view CPU medians is 3.586 ms in V243 and 3.369 ms in V244; timings remain broadly comparable and vary by view. Peak observed texture storage is 144.79 MiB versus 147.46 MiB. The added street atlas is exactly 2 MiB; existing cache page dimensions/UVs are reused. Six cached sections replace the western fence's individual picket primitives. There are no new simulation nodes, particles, shaders, render targets or per-frame texture uploads.

## Packaging and limits

The Web PCK is patched selectively from completed V243; untouched runtime entries retain their exact bytes, including original source/export differences. Modified resources match Editable and Server Update. Exported settings retain their existing values with application version 244. HTML PCK/WASM sizes match the actual files. Production Web contains no V244 QA scripts or source-art originals. CRC, duplicate-path and cache-exclusion checks are recorded in `RELEASE_INTEGRITY_V244.json`.

Physical school-device benchmarking, live multiplayer/account connectivity and external deployment remain unperformed. Native QA inherits an ObjectDB/three-resource cleanup warning after successful completion; no final in-session script errors were observed. No deployment was performed.
