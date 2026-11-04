# Crossroads V262 — Battlegrounds artwork update

Complete release based on authoritative V261. Godot 4.5.1. Build `V262-battleground-art`; report schema 3 and network protocol 11 are unchanged. Nothing deployed.

## Artwork

Both official maps, Verdant Front (`woodland`) and Iron Rain (`warzone`), are updated in both 3v3 and 4v4 formats. The V207/V208 style remains soft coloured edges, matte shading, readable painted pixel clusters and neutral idle poses. Each faction keeps its own designs and palette.

Wildwood's capital retains its teal central roof, flanking towers, arched door and steps, now with weathered limestone, carved leaf detail and restrained moss. Ironhollow retains the corresponding copper-brown roof, twin towers and arched entry, with heavier grey masonry and iron bands. Each faction has a matching detailed barracks gatehouse, pennants and upgrade bench. Capital and barracks drawing rectangles stay 320×240 and 230×195; service/healthbar anchors remain in place. Destroyed barracks have rubble artwork while keeping their original state and health display.

The central warforge keeps its original location, striped teal/beige awning, counter, merchant and E interaction, with improved stone, timber, supplies and tools. Its drawing envelope remains 210×150. Barracks recruitment icons now use the same sharper troop artwork as the battlefield. Existing CC items and their previous upgraded icons are retained.

Verdant Front uses detailed grass/clover, soft-edged earth lanes, painted tree cover, log checkpoints and irregular woodland pools. Iron Rain uses ash and slate grit, compacted roads, detailed craters, sandbags, bunkers and textured rock cover. The existing horizontal march roads remain 240px wide, cross-lanes 95px wide and home tracks 200px wide. Offline baked masks soften 12px inside their original rectangles; no road widening or navigation change. Their unions and centre lines are preserved to the integer raster boundary.

The flyover plane is now a detailed overhead sprite on the original path/clock. Falling shells have small matte highlights. The original orange bomb circles, crosshairs, radius, fall timing and damage remain unchanged. Spectators use dedicated small baked overviews of the exact ground layouts rather than rendering thousands of ground cells each frame; buildings, troops and effects still draw at their actual positions.

All 22 existing faction/role designs and 88 source poses are retained. The original high-resolution V231 artwork is normalized into sharper 128px stages using each previous 80px frame's painted bounds. World heights, foot anchors, role scale multipliers, idle/walk/windup/strike/recovery selection and healthbar positions are unchanged. No troop is redesigned or recoloured. Nine shared roles and each faction's one exclusive remain available exactly as before; the opposite faction's reserved art is preserved without making it recruitable.

## Gameplay preservation

All original V261 source files remain present. Every authored scene and content JSON is byte-identical. Battleground constants, state, maps, 6800×4400 field, lane centres, obstacle positions/radii, capitals, barracks, market, hero spawns and troop routes remain unchanged.

All 45 non-replaced Battleground functions are text-identical after normalizing the one recruitment-icon texture binding; the two replaced bodies are draw_world and draw_obstacles. All 144 other Arcade functions and its state/constants remain text-identical; only _draw_world has scoped presentation hooks. battleground_art's warm/pose logic is unchanged; unit/capital texture draws use the new assets. battleground_command, its UI, arena AI, server authority and network-service code are unchanged apart from the release ID. The common terrain cache adds a presentation stamp to refresh ground if a snapshot changes map/layout.

Costs, HP, damage, ranges, speeds, army caps, recruit queues, income, upgrades, orders, recall, healing, respawn, targeting, conversion, projectiles, bomb rules, faction exclusives, rewards, victory conditions and snapshots are unchanged. No balance changes, record resets, schema migrations or live database actions.

## Verification

- 813 focused native assertions and the same 813 browser WebGL2 assertions pass. These cover visible/cached assets, all 88 normalized troop bounds, original world sizes and barracks counts, collision island equality against V261 in all four map/format combinations, read-only rendering, real E access to barracks/warforge, snapshot-layout cache invalidation, retained chunks, mode isolation and a complete 256-unit roster.
- 271 existing Battleground rule assertions pass: commands, targeting/navigation, 32-unit caps, queues, faction exclusives, recall/healing, rewards, siege damage, wire snapshots and gateway validation.
- The V261 arena regression passes all 1,984 assertions. Total current native assertions: 3,068; browser focused assertions: 813. Production Web boot is checked separately with the final runtime pack.
- 36 native and 36 browser captures cover both maps in 3v3/4v4, both capitals, barracks, market, roads/cross-lanes, destroyed barracks, damaged capitals, flyover/impact warnings, both spectator overviews, troop idle/march/attack states and eight armies at the existing 256-unit cap. Before/after boards and a close-up troop sheet are included.
- Inspection states are frozen/repositioned; automated scenarios do not establish a human full-match playthrough, real network latency, hosted-server capacity or school Chromebook frame rates. No day/night cycle is added to Battlegrounds. Native shutdown retains inherited ObjectDB/three-to-four-resource warnings. Final native/browser runs have no script/parse errors or WebGL errors; software-GL screenshot readback may issue GPU-stall diagnostics.

An early browser QA fixture enabled drawing before initializing its Battleground map. The fixture now keeps started=false through loading/asset checks and enables it after _make_floor. The final frozen runtime pack passes all captures and checks; do not copy the earlier invalid fixture lifecycle into future QA.

## Efficiency

New gameplay pages use a conservative decoded RGBA budget of 21 MiB across both maps. A single active map needs at most 15.75 MiB of these pages, shared between 3v3/4v4. Optional spectator overview pages add 7,480,000 bytes across both maps, bringing all eight new pages together to 29,500,096 bytes (28.13 MiB). Pages and AtlasTexture regions load lazily and are cached. Each new atlas edge is at most 1408px.

The two ground atlases deduplicate both team-size layouts: 331 woodland and 329 Iron Rain 64px cells, each on a 1024×1344 page. Ground commands are retained in the existing 512px chunk cache, capped at 48; stationary instances are reused. Atlas subregions draw as retained tiled quads. Map/layout changes invalidate presentation chunks. Shared source trees/rocks are reused. The 256-unit inspection state recorded 565 draw calls in native and browser software GL; this is a fixture diagnostic, not a school-device benchmark or FPS claim.

No new shader, particles, render targets, live lights, physics objects, simulation population, authority tick work or network messages. No per-frame image generation; masks, lane blends and spectator backgrounds are baked offline. Per-unit draws keep the previous transform/healthbar work.

## Packages and installation

Apply Server Update before Web. Preserve server secrets/runtime settings, databases/user data and Web cross-origin isolation headers. Nothing has been deployed.

Editable is the complete project in tar.xz format. Extract it and open Crossroads_Realms_Beyond/project.godot in Godot 4.5.1. All runtime crops, original prior project assets, QA/evidence and production tools are included. Art Sources separately preserves the three new full-resolution generation originals, briefs and hashes; it is optional for editing/running the finished project. Previews includes verified captures and comparison sheets. Integrity records exact archive hashes, sizes and validation.

## Continuation

Use V262 Editable as the next authoritative base. assets/battleground262 contains the fort/scenery/army/terrain/overview pages and lookup metadata. scripts/battleground_art262.gd owns presentation. battlegrounds.gd and battleground_art.gd delegate artwork while retaining authority and pose selection. multiplayer_ground.gd chooses the scoped cached ground path; arcade.gd avoids the former duplicate obstacle draw and routes spectator ground to the overview.

Tools under tools/release262 expect baseline project261/Crossroads_Realms_Beyond, candidate project262/Crossroads_Realms_Beyond, baseline web261/server261 and out262 outputs. Restore Art Sources to art_sources262 for optional preparation; prep262.py then finishprep262.py build the runtime pages. Integration/extension scripts record historical steps and should not be rerun over finished source. Source QA stays in Editable and is excluded from new production Web resources. Use unique frozen QA pack names and never replace mounted packs while tests run. Keep draw lifecycle initialization order intact.
