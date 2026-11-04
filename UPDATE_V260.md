# Crossroads V260 — North Gate: Three Roads artwork update

Complete release based on authoritative V259. Nothing deployed. Godot 4.5.1. Build V260-north-gate-art; report policy 3 and network protocol 11 remain unchanged.

## Artwork and implementation

The North Gate map now follows the V207/V208 soft coloured edges, matte shading and readable painted pixel clusters. Six distinct fort buildings replace the old reused flat sprites: the twin-tower gate, sword-crested blue barracks, warm brick forge with furnace, green archery lodge, plum-roofed sanctum and teal-awning supply depot. Original service names, positions and 260×210/170×150 drawing envelopes are retained.

Bellwood, Millroad and Emberwatch retain their original outpost locations, footprint, health and soldier generation. Their blue, green and clay-red roofs now distinguish three detailed watchhouses. Destroyed outposts remain clearly marked. The courtyard has weathered grey flagstones, layered crenellated walls, painted brazier posts, supply carts and the Gateward Spring fountain. Road markers, banners and checkpoint rails are updated. Existing patrol positions and route formulas are retained; their rendering now correctly accounts for the camera.

Terrain uses the established detailed town grass and soft road masks, new muted flagstone paving, painted wood for the original bridge deck, textured banks on the river and mill pond, detailed trees and rocks, and restrained water ripples. The original road/terrain selection and collision geometry are unchanged. Water is drawn below actors at eight frames/sec with cached images, and leaves the bridge clear. The map remains 10,600×9,400 with the same three lanes, river crossing, courtyard, pond and ruins. Decorative rails do not add collision.

The Tollbreaker keeps its broad brass bell torso, clapper opening, horned helm and slate limbs, now with matte plate detail, rivets and engraved banding. All seven selectable rival NPC identities have updated idle, two walk and attack poses: Sable, Bastion, Cinder, Lumen, Thorn, Iona and Flint. Their palettes, equipment sides and individual designs remain recognisable. Ram guards recover sharper source detail. All eleven actor designs / 44 poses preserve the previous normalized body bounds, world heights, foot anchors, pose selection and combat timing. The changes are selected only in North Gate; the shared unit artwork for other formats remains in place.

## Preservation

All original source files remain present. Every content JSON, authored scene and navigation file is byte-identical to V259, including defense_world.tscn and north_gate.json. All 46 existing non-replaced North Gate functions remain text-identical after normalizing the two presentation-only texture-loader references in setup. Draw-world/base bodies and common rendering hooks are the changed behavior. Routes, obstacles, service interactions, spring healing, gates, outpost health, upgrades, wave scaling, rival behavior, rewards and record eligibility remain unchanged. No balance change, record reset, schema migration or live server/database action was made. All previous V259 fixes and the V258.1 ordinary Training Yard exit are carried forward.

## Verification

- 63,504 focused native assertions and 63,504 browser WebGL2 assertions pass. This includes battlefield collision sampling, route/spawn comparison, party/wave scaling, all 44 actor pose bounds, visible/cached artwork, actual E access to all five services, bounded terrain storage and mode isolation.
- Regression checks: Descent 4,350; portrait/marina/UI 4,450; portals 451; Pippa/decoy 268; current unit tests 671; party selection/play 38; lobby/rival selection 35. Total current native assertions: 73,767.
- Seventeen native and seventeen browser views cover all service areas, all outposts, river bridge, mill pond, ruins, three roads, lost outpost, defenders/rivals and a low-light visibility stress view. Raster coverage checks reject missing terrain areas. Before/after views and a cast sheet are included.
- Gameplay is frozen/repositioned for inspection. The low-light view is a visibility stress tint, not a new day/night mechanic. These tests are not a human full-wave playthrough, a multi-device latency test or a school Chromebook benchmark. Native exit retains inherited ObjectDB/three-resource warnings; current checks contain no script/parse errors. Browser screenshot readback can produce a GPU-stall diagnostic.

## Efficiency

The six new runtime atlas/material pages use 8,912,896 decoded RGBA bytes (8.5 MiB), loaded lazily. Existing tree, prop and water resources are reused. Actor textures and AtlasTexture wrappers are cached; no per-frame image generation, runtime render targets, shaders, particle systems, new lights, physics work or network messages were introduced. Ground commands are retained in the existing 512px chunk cache, capped at 48 retained chunks. Atlas subregions use tiled retained quads so they do not disappear when repeated; shared atlases remain batchable. Stationary chunks retain their instances. Ripples redraw at at most 8 Hz while visible. The final PNG optimization is lossless, with decoded pixels verified identical to the tested images.

## Packages and installation

Apply Server Update before Web. Preserve existing server secrets/runtime settings, user/database data and Web cross-origin isolation headers. Nothing has been deployed.

Editable contains the complete project and every required runtime asset. Extract it and open Crossroads_Realms_Beyond/project.godot with Godot 4.5.1. Art Sources separately preserves all five full-resolution new image-generation originals, references/production briefs and hashes. They are not required to run or edit the included game assets. This keeps the complete growing Editable archive in a single downloadable file without discarding original project files. Previews contains verified native/browser captures and comparison sheets. Integrity records archive sizes, hashes and verification results.

## Continuation

Use this V260 Editable as the next authoritative base. scripts/north_art260.gd owns cached fort art, North Gate actors, material selection and presentation drawing; north_water260.gd owns the visible-only water layer. north_gate.gd retains campaign authority and delegates its two world-art functions. arcade.gd routes North Gate building/obstacle/actor drawings; multiplayer_ground.gd retains its existing cache and uses the scoped North Gate terrain append path. Assets live under assets/north260; QA/evidence under qa; tools under tools/release260.

Production build tooling expects V259 extracted under Crossroads_Realms_Beyond, candidate under project260/Crossroads_Realms_Beyond, old Web/Server in web259/server259 and out260 for outputs. Art Sources can be restored to art_sources260 for preparation. The integration script is a historical initial patch, not an idempotent reconstruction of final source; do not run it on this already completed release. Use the delivered project directly. Freeze unique QA PCK filenames before concurrent checks and never replace a mounted fixture. QA scripts/tools are kept in Editable, excluded from production Web PCK. The scoped unit regression excludes unrelated old cinematic assertions and checks the new North Gate texture bindings.
