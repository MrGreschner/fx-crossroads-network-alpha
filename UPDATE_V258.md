# Crossroads V258.1 — Training Yard walk-out exit

Correction to the complete V258 release. Nothing deployed.

The Training Grounds (`practice`) now uses an ordinary walk-out opening: a short westbound trail, stepping stones, two low wooden fence ends and a left-pointing TO TOWN sign. Its leave portal is removed. Shared portal drawing explicitly skips Training Grounds, including the otherwise-unused boss-exit drawing, so no animated leave portal can appear there. The existing exit anchor remains (250,600), with the same 85px interaction distance. Its prompt reads “E  Leave the training yard”; E still enters town through the original interaction. The hero book, guide, targets, ally/healing target and shot practice are unchanged.

No scene/campaign/region/collision files changed. All three animated portal types in actual realms and their menu icons remain intact. No additional record reset or gameplay balance change. Build is V258.1-training-exit; report policy 3 and network protocol 11 are unchanged.

Verification: 24 focused native assertions pass, including the original exit location, accessible approach, retained target count, prompt and actual E-to-town interaction. The same 24 checks pass in WebGL2 with a browser preview. All 451 V258 portal regression assertions also pass. Updated runtime resources match across Web, Server Update and Editable. Every original source file remains present, with layout data unchanged. No school-device or live-server test occurred. Native shutdown retains the inherited ObjectDB/three-resource warning; checks have no script/parse errors.

The existing V258 download items have been updated in place. Use the updated Server Update before Web; preserve secrets/runtime configuration and user/database data. Editable remains the complete Godot 4.5.1 project in `.tar.gz` format. Previews retains the previous portal-update images/animation and adds native/browser Training Yard exit views. The original Art Sources package is unchanged. The following V258 release notes describe the retained portal update and its original verification; the Training Grounds exception above supersedes its former portal rendering.

# Crossroads V258 — Living Portals

Built from the authoritative complete V257. Artwork, integration, verification and packages are finished. Nothing has been deployed.

## Three identities throughout the game

Normal portals use a weathered blue-grey stone arch with sage/teal inlays and a calm teal vortex. The Between uses a fractured plum stone ring, amethyst joints and a violet vortex. Overcharged portals use a reinforced honeystone/bronze arch with an amber crystal crown and a gold vortex. Each is a distinct painted frame, with soft coloured edges and matte shading following V207/V208. Their masked interiors swirl and carry small moving sparks. Twenty-four frames at twelve frames/sec form a two-second loop for each identity.

The central town portal, the three portal-menu icons, all 25 authored realm entrance/return markers and their exit drawings use the shared artwork. Normal exits stay Normal; Overcharged return and completion portals use gold; the Between uses its violet shared arrival/extraction crossing in solo and network co-op. Attunement shares the Between identity, so there are exactly three portal types. The town hub remains the Normal gateway while its menu displays all three route identities.

Custom exits are covered too: school street exits, Neon Crucible, Cinderheart, Confluence, the Chimevault's final exit, Oath Nexus links, the old Oath exit and the Unwritten Depth's true exit. Oath/Chimevault frames are drawn beneath actors while their existing labels remain in the overlay pass. Chimevault's first two mechanical lifts retain their own design; the final portal is muted until its original conditions permit use. The Studio realm-test exit also uses the new animated Normal texture. Doors, stairs, mechanical gates, map travel routes, ability effects and the title cinematic are separate objects and retain their designs.

## Preservation and mode selection

This is a presentation update. Every existing campaign JSON, region JSON, scene, navigation cache, enemy definition, reward, service point and authored collision file is byte-identical to V257. Portal anchor positions stay at the existing scene/interaction coordinates. Ordinary realm sprites retain the original 80×120 drawing rectangle at (-40,-76) relative to the interaction point. The town retains its 126×161 rectangle and existing foot/aperture alignment; menu controls fit the same layout envelopes.

Mode selection reads the active solo Waylight controller or the actual network expedition controller. Local arcade scenes have no expedition controller and safely fall back to Normal; attunement maps to Between. Town/arena states do not inherit stale expedition colours. Co-op reads ReturnGate/Boss positions once from the scene it already loads; this adds no network state, protocol field or geometry. Its incoming marker is visual and does not add an abandon interaction. Classic co-op's automatic completion remains automatic. Existing manual co-op exits and the Between's shared extraction retain their original conditions and distances. The client/server protocol remains 11 and report policy remains 3.

No additional record reset or migration is introduced. V257's existing Sunfield course-revision migration is carried forward unchanged, along with all previous work. Separate functional exit locations such as Confluence's inherited boss-position finish and east exit remain visible; co-located controller/core exits avoid redundant overlapping art where applicable.

## Verification

57,631 passing engine assertions: portal update 451, Sunfield 4972, Firstbell 4388, Honeyglass 3212, Grove/Quarry 171, aquatic 35637, Descent 4350, marina/UI 4450. Portal tests actually launch all 25 requested realms, check their Normal/Overcharged selection and reset, compare network portal anchors to original scene markers, check actual Between/attunement selection, manual Normal/Overcharged Sunfield extraction, the two-player Between extraction condition, atlas/frame reuse, all 72 distinct frame images, loop indices, muted art and server/Studio compilation. Production network co-op is tested through its network controller; local arcade remains compatible without one.

Independent pixel continuity checks compare the loop's last→first transition to every adjacent frame transition. All three wrap transitions stay within the ordinary per-frame change range; the aperture mask stays registered with its painted frame throughout the loop.

Sixty native previews cover the entrance and ready exit for all 25 authored realms, both charged endpoints, the Between crossing, town portal, route menu, synthetic low-light views and network co-op examples. Seventeen representative WebGL2 previews plus the production browser menu pass. Fixtures freeze authority, reposition cameras/players, clear patrols and set completion flags for inspection; they do not represent a complete human playthrough of every realm. Some deliberately centered entrance views expose the existing map boundary outside the normal clamped gameplay camera. Low-light views are visibility stress tints; the town view uses its existing lighting. A six-second MP4 shows the real game atlas enlarged at normal animation speed.

19,148 existing Editable files remain byte-preserved, every original file remains present, and all 21 changed/new runtime resources match across Editable, Server Update and the Web PCK. Unchanged Web resources match V257, except the versioned project-settings binary. Archive integrity receipts include byte sizes and SHA-256 hashes.

## Efficiency and practical limits

The new 896×1296 shared atlas uses 4,644,864 decoded RGBA bytes (4.43 MiB). The previous town/menu portal atlas used 5,087,232 bytes: this replacement is 442,368 bytes, or about 8.7%, smaller in decoded payload while increasing each identity from 16 to 24 frames. All 72 AtlasTexture wrappers and the underlying image are lazy-cached. Each visible portal needs one texture draw. There are no new shader passes, real-time lights, particles, animation nodes, physics updates or network packets. Old source artwork stays in the complete project for preservation but the old town/menu portal atlas is no longer requested by its renderer. The old small portal bitmap may still be used by unrelated presentation/navigation thumbnails.

`qa/evidence258/render_budget.json` records observed renderer metrics. Actual school devices and multi-device latency were not benchmarked. Native fixtures retain the inherited ObjectDB/three-resource shutdown warning. Isolated browser startup can report unavailable external-service fetches; final checks contain no script/parse/page/WebGL errors. No live backend changes or deployment occurred.

## Packages and continuation

- Apply Server Update before Web; keep secrets, runtime settings and user/database files. Import with Godot 4.5.1 as needed. Preserve the existing browser isolation headers.
- Editable is the complete standalone Godot 4.5.1 project in a `.tar.gz` archive to keep the full growing source in one downloadable file. Extract the archive (and its `.tar` layer if your unpacker exposes one), then open `Crossroads_Realms_Beyond/project.godot`. No original files were discarded to reduce package size.
- Previews contains native/browser captures, coverage contact sheet, enlarged portal poster and normal-speed animation.
- Art Sources contains all three full-resolution built-in image-generated frame originals, exact prompts, hashes, style reference and production brief. Mask fitting/downscaling and animation baking are technical derivatives; the originals are preserved.

Use V258 as the next base. `scripts/realm_portals258.gd` owns shared textures, mode selection and common drawing. `town_portal247.gd` remains a compatibility wrapper for town/menu callers; `portal_route_art.gd` keeps its lightweight visible-only 12fps redraw cadence. Assets are under `assets/portals258`; preparation/build/QA/preview tools are under `tools/release258`, with tests/evidence under `qa`. Build tooling expects the complete V257 Editable ZIP under base257, extracted web257/server257, and the current source under project258. Preparation can use the three packaged source originals. The integration script is historical patch tooling for a fresh V257 tree; do not re-run it on an already integrated project. Freeze/copy the QA fixture PCK before concurrent verification; never replace a mounted fixture during a run. Current browser tooling uses the frozen QA run4 fixture. Future changes should produce a new fixture filename.
