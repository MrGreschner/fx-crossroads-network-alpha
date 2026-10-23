# V198.39 validation

Build: `V198.39-town-rendering`. Baseline: cumulative V198.38. No production deployment, database connection or account mutation was performed.

## Current native checks

| Check | Result |
| --- | --- |
| V198.39 town | 1,934 checks, zero failures |
| V198.28 marina life / trader / guard route | 5,470 checks, zero failures after clearing two existing crate obstructions |
| V198.30 marina streets / weekly resident routes | 21,165 checks, zero failures after clearing the Exchange cliff approach and cargo obstructions |
| V198.38 records / realm mechanics / Battlegrounds | 61 checks, zero failures |
| V198.37 gameplay / Descent / items | 308 checks, zero failures |
| V198.37 Academy / Studio program | 82 checks, zero failures |
| Native atlas pixels | All 57 trimmed regions match their native bake pixels exactly |
| Terrain atlas pixels | All eight tile regions match the original PNG pixels exactly |

The current town test verifies all atlas bounds, the shared terrain texture, bounded additional scenery texture memory, exact lighting falloff at every retained grid vertex across five time/weather combinations, no timed rebuild at a stationary camera, one rebuild at a camera-grid crossing, marina deck/water collision, all sampled guard positions, the Exchange approach, and no profile changes from rendering checks.

The benchmark uses the same native script against the uninstrumented V198.38 and V198.39 clients. It samples four locations in daylight and darkness, plus walking through the square and marina. Detailed samples, local median/p95 timings and method limitations are in `PERFORMANCE_V198_39.json`. Day/night native screenshots were visually inspected. Rendered paths, marina details, facades and lighting retain their authored positions; no resolution reduction or zoom change is used.

## Package checks

The release process checks source/server/client-pack byte parity for every changed runtime resource, removes obsolete compiled-script remaps for edited files, excludes private backend and QA files from the web pack, and verifies ZIP CRCs. Server ZIP contains the existing Docker deployment entry points, Web ZIP has `index.html` at its root, and Editable ZIP retains the complete Godot project and source/bake tools. No environment secrets, cache/dependency directories or executable binaries are added to the ZIPs.

The actual client PCK is additionally loaded in native Godot with the current town and Academy/Studio tests. The web build is loaded in Chromium with software WebGL, through the opening sequence and main menu into town, then moved with keyboard input while watching for script/parse errors. Browser captures are internal QA only.

## Limits and historical checks

- The benchmark host uses Mesa llvmpipe software OpenGL, not Intel/AMD integrated graphics. Draw-call savings are concrete; classroom FPS and frame pacing require testing on the affected computers. Local frame timings fluctuate with host load, and not every sampled view has a lower median frame time in every run.
- The old V198.12 performance harness assumes the old lighting vertex-colour representation, its exact V198.12 release string and older Honeyglass floor-stamp counts. Those assertions are superseded by the current town lighting/pixel checks; Honeyglass gameplay was not modified in this update.
- Existing Godot test-process shutdown warnings about ObjectDB / three retained resources still appear. The town pass does not claim to repair that separate teardown issue. No runtime script or parse errors were observed in the successful current checks.
- Live Render database, school authentication and itch.io deployment have not been tested or changed in this session. This release requires no schema migration or save reset.
- Teacher/assessment APIs are unchanged. Existing client program checks pass; no new production student data was used.

