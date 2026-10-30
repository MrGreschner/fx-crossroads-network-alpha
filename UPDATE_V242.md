# Crossroads V242 — shops and public buildings

V242 finishes the shops/public-buildings artwork batch on the complete V241 baseline. It is packaged, not deployed.

24 original facade frames serve 25 placements: Character Hall, Bartle’s Supply Vendor, Moss’s Food Stand, Tessa’s Healer House, Wayfinder Lodge, Rowan’s Seedhouse, Training Yard hall, Gleam Atelier, Squirrel Post, Mistglass Spire, Ramguard Barracks, Fellowship, Relay Workshop, Watermill, Gatherers’ Lodge, Willowglass Apothecary, Ripple & Reel, Crossroads Market, Market Office, Wayfarer’s Rest, Hearth & Crumb, Quest Reading Room, the marina bait stall and both market arcade booths. Each retains its own form, palette and service details. Earned buildings still require their original unlocks; unbuilt projects remain construction sites. The unused Chimehouse renderer is not substituted for the active Gatherers’ Lodge.

The artwork uses soft coloured contours and matte storybook materials, with small nearest-neighbour runtime textures. V241 landmarks and V240 improvements are retained. Homes, vegetation, North Gate infrastructure and general street details remain for later town passes.

All world anchors, original sprite envelopes, collision functions/constants, roads, services, prices, progression, education content and NPC routes are unchanged. The waterwheel, workers, carts, patrols, pavilion chimes and other live details remain. Window emission uses offline masks fitted to the new glass, excluding stone, frames and mullions. Local light sources sit on actual emissive pixels; the Mistglass gate retains cool teal emission.

Rendering uses one shared 2048 × 1024 albedo atlas (8 MiB decoded), one compact 1024 × 512 emission atlas (2 MiB), and three offline architecture caches (3.61 MiB total). Those caches replace the former market, post and marina-fittings paths. Assets are cached, culled and reused. No runtime viewports, full-resolution source image loads, per-frame image creation, new NPC simulation or particles are added. This is not a school-hardware performance benchmark.

Validation: 233 focused checks pass against source and the patched Web PCK. V241/V242 comparisons match all 4,752 sampled collision/approach results in built and unbuilt states; every recorded entrance is reachable. 7,217 existing functions, 1,301 constants and 477 protected content/scene/art resources remain unchanged. All 24 facade views were inspected in day and night in Godot 4.5.1’s compatibility renderer; the unbuilt-project state was also checked. The server passed a fresh import and script compilation. Package integrity and source/server/PCK parity are documented in VALIDATION_V242.md. Native fixture teardown retains the baseline three-resource/ObjectDB notices, with no in-session script errors. Browser and actual school-device playtesting remain outstanding: browser-runtime installation was unavailable in this environment.

Install **Server_Update first, then Web**. No database migration or record reset is required. Existing service configuration, databases, player progress and deployment procedures are retained. No deployment was performed.

Editable includes accepted generated originals, all prompts, identity/style references, atlas preparation code, layout records and QA fixtures. See ART_SOURCES_V242.md. In-game previews are available separately in V242_Previews.zip.
