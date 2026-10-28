# V237 performance audit

The largest confirmed issue was animation timing, rather than a server limit. The opening advanced at most 0.05 seconds per rendered frame. At 10 FPS, its 22.5-second scene lasted 45 seconds. The revised visible-tab timeline finishes in 22.5 seconds at the same simulated frame rate. Hidden tabs pause the scene, and resuming does not skip the story.

## Changes

- While the browser opening owns the screen, the covered Godot game subtree is disabled and its render loop is suspended. Finish, Skip and error recovery restore the previous state. This prevents the menu/town from competing with the cinematic. Native intros also skip the covered world draw.
- All latest hero poses were packed losslessly into one 1344 × 3024 texture, with gutters and exact original 80 × 80 cells. It includes 498 addressable pose frames plus 79 prepared portraits (566 unique regions after deduplication). The startup roster's 476 loaded pose views now share one GPU texture. Visual proportions, ability frames and gameplay remain unchanged.
- Hero portraits and menu sprite bounds are prepared ahead of time. This removes Character Hall resizing/readback and menu measurement readbacks from the normal official-hero path. Custom artwork retains its existing fallback.
- 590 superseded hero PNG resources are omitted from the downloadable runtime pack. Individual editable drawings remain in Editable. No art is resampled or palette-reduced.
- The intro caches its day/night backdrop, uses 10 creek strips instead of 20, caches DOM lookups/pose changes and limits visual updates to 30 Hz. Its canvas starts at 960 × 540 for devices reporting at most 4 GB memory or 4 logical cores. Other devices start at 1280 × 720. Sustained measured painting cost can reduce the cinematic to 960 or 640 pixels wide; story timing and controls stay the same. This reduces cinematic pixel workload by 44% or 75%, respectively. It is not a gameplay camera change.
- Terrain chunk visibility is reused until chunk coverage, mode or region changes. Camera transforms still update normally. Town light lists are recollected only when their retained light field changes; visible lamps remain aligned as the camera moves.
- Existing diagnostic reports now identify this build and include the opening's painted-frame count, painting time, rendering size and quality changes, plus hero texture/frame counts and terrain visibility updates. No new collection endpoint or personal information was added.

## Verification

1,662 focused checks passed, including byte-for-byte comparison of every pose and prepared portrait against V236, shared textures, bounds, terrain reuse, light reuse and cover/uncover restoration. The shared hero/stat/Cave regression passed 4,574 checks. The final Oath progression suite passed 635 checks. Fifteen JavaScript harness checks cover 10-FPS timing, hidden tabs, completion, Skip, failure recovery, rendering size and bounded adaptation. The harness uses simulated DOM/canvas calls, not a real browser GPU.

A native compatibility-renderer run used Mesa llvmpipe at 1280 × 720. Each town sample discarded 15 warmup frames and measured 50 draws. These values measure CPU time submitting draw commands, not GPU frame time or school-PC FPS. A second local run varied enough that a general town-FPS improvement cannot be claimed yet.

| Town position | V236 median CPU draw | V237 median CPU draw | V236 p95 | V237 p95 |
|---|---:|---:|---:|---:|
| [950.0, 800.0] | 4.148 ms | 4.098 ms | 5.032 ms | 5.844 ms |
| [1300.0, 1680.0] | 2.912 ms | 2.916 ms | 3.861 ms | 3.899 ms |
| [-650.0, 1000.0] | 3.244 ms | 3.159 ms | 4.247 ms | 4.145 ms |

Native setup in this final paired run: 4.69 s before, 4.50 s after. These single startup measurements are noisy; no broad startup-speed claim is made. Town draw-call counts were unchanged in this run.

The existing test fixture reports retained ObjectDB/resource references during shutdown. No in-session script errors were observed in the successful suites/native profile. A local browser binary could not be provisioned in this environment, so actual browser playback, input restoration and school-device FPS still require testing. The supplied next play logs should guide further work on specific realms, scene draw calls and devices.

Moving game authority or the opening to the server would not remove the browser's pixel drawing work. These changes address local work directly. Remote video rendering would be a different streaming architecture with latency and hosting costs; it is not part of this update.

## Deployment and follow-up

Back up and deploy Server_Update first, then Web. No database migration, record reset or balance change is included. Nothing has been deployed by this task. Check normal intro completion and Skip, then walk around town and open Character Hall on one affected school PC. Supply the existing play/performance report after those tests, including the intro section when available.
