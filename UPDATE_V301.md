# Crossroads V301 — Oldwater Lake

Oldwater Lake's environment has been rebuilt with32new scenery designs,8distinct noncircular rock hazards,6material sources,174scenery placements and63paged terrain textures. The9000x6800world,existing island centres,9camp enemies,43existing hazard locations and4original underwater landmark locations remain.

Birch Landing is a long inhabited woodland island with a cove, fisher's cottage, birches, willows, stone landing and gravel trail. Oldwater Isle has a northern headland, ruined gateway, pillars, layered granite and overgrown paths. Reedwatch is narrower and taller, with a timber lookout, reed/bulrush banks and wetland vegetation. The mainland now has an irregular bank, natural shoreline materials, a connected timber harbour, boathouse, gateway, net racks, rope posts, lantern and fishing equipment. Submerged ferry/mast/arch/statue/weed details mark the lake's existing points of interest. Deep/shallow water, wet gravel, meadow, granite and old planks replace flat colour/circle primitives. Sparse wind/current strokes remain cosmetic. The existing boat artwork and original night/rain/weather lighting remain.

## Shared geometry, not cosmetic circles

All three islands use authored irregular outlines sampled to80points, with distinct proportions, coves and headlands. The SAME polygon model drives terrain baking, chart outlines, shoreline queries, boat obstruction, landing and on-foot boundaries. The mainland bank uses86shared anchors for art and boat clearance. Land remains walkable under decorative scenery; raised props fade beside the hero.

The43original lake hazards now use8distinct cracked ridges, angular slabs, branching reefs and irregular boulder shapes. Their concave collision polygons are derived from each normalized sprite's opaque silhouette (2.3source-pixel maximum simplification tolerance), preserving L-shaped gaps rather than replacing them with convex hulls or discs. Boat motion uses swept polygon checks with the original25world-unit boat padding. Clear water inside a former circular collider can now be passed where the boat fits. Fast movement cannot tunnel across a rock. Rock positions/count and nominal radii are unchanged. Rock impact remains12hull, debris8hull, and impact immunity1.2seconds.

## Preserved systems

All fishing habitats/species/availability, bait, gear, anchored casting, cage rules, cargo, release log, capacity, XP/record banking, storage, session-only voyage rules, fail/abandon behaviour, island camp actors, combat stats,35hull single-use repair, currents, controls, weather, civil clock and day/night darkness remain original. Existing island centres and all9spawn points remain on land. Only the requested lake geometry and presentation changed. Decorative buildings/scenery add no new invisible movement colliders or merchant interactions. Cages now have detailed markers while their original ready timer/contents are retained.

Coastal waters are deliberately left for the next update: their island-radius fallback, circular rock rules, waves, debris, nightly island, currents and artwork remain unchanged. V299FirstSteps/Descent fixes and V300Between21permitted-environment pool remain intact;expert/extreme environment exclusion still applies there. SUBVEIL untouched. Nothing deployed,deleted or reset.

## Verification

Exact21495savedV300sourcefiles were hash-verified before editing.2611new native checks pass, covering valid irregular coastlines, draw/radius agreement, landing/boarding, all43hazards/8variants, swept collision, clear spaces formerly blocked by circular hazards, mainland bank collision, all9camps, fishing habitats, actual cage deployment/ready retrieval, repair gating/single-use, unbanked catches, safe banking/idempotence and coastal fallback preservation.

3921retained voyage checks pass using an updated fixture that compares anchored movement with the same large wave unanchored. The untouched V198.31 test initially failed its obsolete <45unit anchor-drift bound; the exact pre-V301water_voyage script reproduces the same81.272unit drift/failure. Current anchored drift81.272 is less than unanchored141.784;production wave/anchor code was not altered. Baseline and updated-fixture evidence retained.

9267static checks pass, including unchanged original assets/content/scenes, function-scope audit and480independent terrain-image readbacks showing warm land inside each live collision contour and water outside. Only rocks,obstruction,draw_chart,draw_ground changed in water_voyage;only radius changed in voyage_islands. Every fishing/cargo/banking/repair/clock/wave/debris/combat function remains byte-identical.

36softwareOpenGL render checks pass with12controlled actual solo-scene captures, some manually framed:harbour,island approaches/landing,ruins,Reedwatch,submerged landmarks,rock hazards,cage/fishing,chart,night lantern and mainland bank. Saved boat/cargo/camp state remains unchanged during drawing. Terrain loads/draws are culled with a12page normal cache. These are not human full voyages, real browser playtests, remote multiplayer tests or classroom hardware benchmarks. Native/runtime checks used Godot4.6.3;target4.5.1 retained. Existing ObjectDB/three-resource shutdown warnings persist.

Four original generated masters,exact prompts,normalized assets,shared geometry,baseline/before-source,normalization/raster checks,QA/logs and packaging tools are retained in tools/release301. Low-alpha coloured fringe pixels in the transparent masters are removed during normal sprite alpha normalization;the final game atlases have clean transparent edges. Initial overly strict aesthetic aspect-ratio assertion was replaced by an actual noncircularity check;all final tests pass.

## Packages and recovery

Web/Server are incremental builds from verified savedV300packages,not fresh4.5.1exports. Changed runtime files match source/PCK/Server byte-for-byte. ZIPCRC/SHA,exact PCK part reconstruction and exact editable-source reconstruction are verified. The real Godot JS wrapper/reassembly integration uses a WASMstub;actual browser/itch preview remains pending. Web retains the verified split-pack loader;each extracted file is below200MB and total below500MB. The whole ZIP may exceed200MB.

Editable restore: extract ALL FOUR V278Editableparts, then finalV293RecoveryDelta(libfile_9849168108cc8191a7cd3aa1602a2814), then finalV301RecoveryPatch. This patch is cumulative294–301 over EXACT finalV293,including V298itch packaging,V299fixes and V300Between. Do not overlay older294–300patches afterward. Patch alone is NOT standalone. Open Crossroads_Realms_Beyond/project.godot. Keep V300 rollback and all required base dependencies.

Deploy matching V301Server_Update via establishedGitHub/Renderworkflow,retaining environment variables,secrets,database/storage. Then upload ENTIRE V301Web ZIP to the existing itch.io HTMLgame page and mark it playable in browser. Check preview/login/lake launch/steering/landing/fishing/cage/cargo/home return. No live deployment was performed here.

Next visual queue: Coastal Voyage → Wayfarer Wilds → Mistglass Rift. Challenge Hall's five challenge maps still need a separate art pass;building was updated earlier. Storage safeguard remains active;never delete protected dependencies automatically.
