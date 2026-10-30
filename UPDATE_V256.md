# Crossroads V256 — Firstbell Elementary (realm 4)

Completed 29 October 2026. Built on the authoritative complete V255. Packaged and verified; nothing deployed.

## Artwork

Eleven painted assets update Firstbell's cream/sage classroom linoleum, blue-grey asphalt, school lawn, sand, honey-oak desks, green chalkboards, blue locker trios, yellow/sage climbing frame, blue slide, wooden benches and stone entrance gateway. Soft coloured edges, matte shading and readable pixel clusters follow the V207/V208 direction. All 31 prop markers retain their original position, size, alpha-fit dimensions and collision bounds. Entrance art uses the same location and decorative envelope. Native door panels and street lamps have matching soft colours; no new light nodes or particles.

The duplicate entrance room label is suppressed in favour of the school name on the lintel. The decorative foyer picture moves up within the foyer, and the street title moves below the crossing, clearing inherited overlaps. These are presentation changes only; authored prop markers, rooms, doors, NPC/service points and objectives are untouched.

## Preservation

The Elementary campaign JSON, region JSON and scene remain byte-for-byte unchanged: ten connected areas, 31 props, four doors, two classroom Lesson Wardens, the 420-HP playground guardian, eight return patrols, the 650-HP Last Bus, merchant and street exit. Bus hit radius (85), attack timings, summons, damage, rewards, unlocks, save formats and all other combat behaviour are retained. No character/boss redraw or balance change was made. The complete V252 aquatic update and V253–V255 realm work are included.

Rendering is scoped to Elementary. Entering Middle or High School restores their original textures; returning to Firstbell restores the new art. Both solo and co-op use the same assets and campaign geometry.

## Verification

52,208 passing assertions: Firstbell 4388, Honeyglass 3212, Grove/Quarry 171, aquatic 35637, Descent 4350, marina/UI 4450. Firstbell tests exercise actual patrol spawning, all door milestones, guardian spawning/defeat, return patrols, bus spawn/defeat and school completion. They also check unchanged collision after drawing, cached texture reuse, retained floors, other-school texture isolation, co-op geometry and server compilation.

Before/after navigation comparison samples 17,280 positions in each of five door states (86,400 total); occupancy hashes and all 205 route results match. 19,090 existing Editable files are byte-preserved; every original file remains present. Changed runtime files match across Editable, Server Update and Web PCK; unchanged Web resources remain identical. All ZIP archives pass CRC and duplicate-path checks.

Fourteen native and fourteen WebGL2 previews cover classrooms, foyer, Colour Hall, entrance, climbing frame, slide, street, low light, both bosses, charge/horn warnings and two co-op views. The production browser menu opened successfully. Low_Light_Entrance is a synthetic visibility stress tint, not a new school day/night mechanic. Fixtures reposition players/remove foes for scenery; boss pictures call the actual spawn and telegraph methods.

## Efficiency and limits

Seven prop/entrance frames share one 1024×256 atlas; four terrain frames share one 256×256 atlas. Together these add 1,310,720 bytes (1.25 MiB) of uncompressed RGBA payload, excluding existing game/driver overhead. The original 3,874 retained floor tiles and 101 floor chunks (including background) remain bounded and reused; view culling remains active. Texture creation is lazy and cached. No per-frame terrain rasterization, new animation nodes, shader or physics work.

`qa/evidence256/render_budget.json` records observational before/after software-renderer counts. Actual school hardware was not benchmarked. Native QA retains the inherited ObjectDB/three-resource shutdown warning; local browser startup can report unavailable external-service fetches. Final verification has no script/parse/page/WebGL errors. No live backend, multi-device network test or deployment occurred.

## Packages and continuation

- Apply Server Update before Web. Back up/stop the server, overlay while preserving secrets, runtime configuration and user data, import with Godot 4.5.1 as needed, and restart normally. Retain existing browser isolation headers.
- Editable is the standalone Godot 4.5.1 project. Allow editor import to finish. All authored layout markers remain editable.
- Previews includes native/browser captures and V255-left/V256-right comparisons.
- Art Sources includes all eleven full-resolution originals generated with the built-in image tool, source hashes, production brief and stable source references. Runtime atlases use only technically normalized derivatives.

Use V256 as the next base. `scripts/firstbell_art256.gd` owns cached art and retained presentation; `school_world.gd` selects it only for Elementary and `school_floor_chunk.gd` retains its terrain commands. New images are under `assets/firstbell256`. `tools/release256` holds preparation, build, preview, browser and packaging tooling. Preparation expects a fresh V255 under project256 plus the eleven originals in sources256. Preservation builds expect the V255 archives under base255 and extracted web255/server255. The separately saved Working Checkpoint is a recovery patch, not a release package; use this completed release for future development.
