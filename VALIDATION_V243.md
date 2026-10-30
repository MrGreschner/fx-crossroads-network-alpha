# V243 validation

## Preservation

The completed V242 Editable archive was used as the authoritative source. All 15,222 unchanged baseline files are byte-identical, including 11,822 original artwork, scene and content files. All original script state/constant declarations are unchanged except the release stamp. 7,252 original functions remain byte-identical. 17 renderer/setup method bodies change as recorded in `tools/verification243/source_preservation.json`; no movement, collision, service, route, harvest, curriculum, progression or economy method was changed.

V242 and V243 contracts are exactly equal: 12,486 collision/entrance/tree/world probes across built/unbuilt states, original anchors, homes, art canvases, roads, wall solids, service points and tree locations; 315 resident schedule states (21 residents × 5 times × 3 weekdays). Both duplex doors and the Tidekeeper entrance are included.

## Runtime and artwork

- Editable runtime: 2,938 checks, zero failures.
- Packaged-runtime fixture using the production PCK resources: 2,938 checks, zero failures.
- Protected V242 shops: 233 checks, zero failures using the V243 release stamp.
- Actual Server Update directory: fresh editor asset import completed, then dedicated `network/server.gd` check-only compile exited successfully.
- Shared atlas reuse, all 20 frames, six fitted glass masks, mask containment, two side-window light anchors per home, fixed-root one-quad implementation, bounded one-pixel sway, 18 glints on leaves, UV clipping and area conservation checked.
- Forty-one final native captures rendered from the packaged-runtime fixture: 18 areas in day and night, apple shake/drop, watered garden and three canopy phases. Final labelled boards were visually inspected. Smoke, doors, window illumination, species/roof identities and retained lanterns checked.
- The QA pack adds test scripts only; the production Web PCK contains no V243 fixture scripts or source-art originals.

## Rendering measurements

Godot 4.5.1 stable, Compatibility renderer, Mesa llvmpipe software OpenGL, 1280×720. Same frozen fixture, four camera locations, noon and 23:00 local time. Each view warms for 15 frames and samples 30 more; median CPU draw-function duration and renderer draw calls are recorded. V242 and V243 ran sequentially with no concurrent visual render jobs. These are indicative native measurements, not browser or school-hardware frame-rate benchmarks.

| View | V242 draw ms | V243 draw ms | V243 p95 ms | V242 calls | V243 calls |
|---|---:|---:|---:|---:|---:|
| Homes Day | 2.232 | 1.809 | 2.100 | 160 | 149 |
| Communal garden Day | 2.611 | 2.120 | 2.729 | 270 | 223 |
| Woods Day | 2.221 | 2.139 | 2.656 | 200 | 216 |
| Marina Day | 2.420 | 2.440 | 3.155 | 252 | 206 |
| Homes Night | 2.173 | 2.681 | 3.031 | 185 | 175 |
| Communal garden Night | 2.619 | 2.683 | 3.036 | 308 | 263 |
| Woods Night | 2.483 | 2.682 | 2.953 | 244 | 260 |
| Marina Night | 2.400 | 2.595 | 3.163 | 274 | 230 |

The new atlases require 5 MiB decoded RGBA; observed steady-state texture usage changes from about 129.9 MiB to 133.1 MiB because the replacement also avoids some old home/tree texture loads. The tree sway uses cached UVs and one quad, no particles, shaders, nodes or new render targets. Existing ground pages remain shared. Draw calls fall in six of eight sampled views, with a 16-call increase in the woods view from the small ground-paint exclusions/reed draws. Per-frame texture creation is absent.

## Packaging and limits

Web resources are patched selectively into the completed V242 export. Every untouched PCK resource is preserved byte-for-byte. Exported project settings are retained with only application version updated. Modified resources are byte-identical across Editable, Server Update and Web PCK; HTML PCK/WASM byte sizes match. Archives are CRC checked with no duplicate paths and exclude transient caches and hidden staging files. See `RELEASE_INTEGRITY_V243.json` for final values.

Actual browser execution and physical school-device testing remain unperformed. Native fixtures inherit an ObjectDB/three-resource cleanup warning at shutdown after successful completion; no final in-session script errors occurred. No deployment was performed.
