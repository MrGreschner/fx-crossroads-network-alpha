# Crossroads: Realms Beyond — V244

**Step 4: street details and town-wide review.** Based on the completed V243 release. The four town-art batches are complete in this packaged update; nothing has been deployed.

## Artwork and integration

Benches, picket fences, the earned Veteran Gate wall and buttresses, north gate, ram banners, roofed town notices, plain adventure board, postal and moving market carts, export crates, handled baskets, net, rope coil, fish rack, both river bridges, lookout, arena guard shelters, construction barriers and crane scaffold, tent, campfire base, log seat, mushrooms, expedition telescope, weekly fruit/fair stalls and picnic blanket now use the established soft coloured edges, matte shading and readable pixel clusters. Each keeps its own design and existing purpose. Existing hero/NPC sprites are unchanged.

Twenty-eight accepted originals produce twenty-nine runtime frames (the home bridge has its own fitting). The two bridge rail lines are pinned to the original 220-pixel deck spans and respective 130/110-pixel deck heights. Three remaining flat garden-island paintings reuse the accepted V243 seven-flower artwork in their original footprints. Watermill and Mistglass Spire lettering is refitted inside the actual sign panels. Labels remain live text. The northern approach path now draws beneath the gate roof, using the same geometry.

World locations, scale canvases, road and bridge geometry, collisions, entrances, service points, progression flags, NPC/patrol routes, garden/fruit behavior, weekly event timing and the economy remain authoritative in their original owners. Existing light sources, campfire timing, fish motion and moving-cart loops remain live. The artwork adds no simulation entities or new light sources. Approved V241 landmarks, V242 building artwork, and V243 homes/vegetation are retained.

## Efficiency

New street art shares one 1024×512 texture (2 MiB decoded RGBA). Static scenery edits reuse four existing cache pages without changing page dimensions or UVs; every texel outside the recorded replacement masks is identical. The long western fence uses six cached sprite sections instead of individual picket/rail primitives. Draw calls fall in all 24 sampled native day/night views; CPU draw timing remains broadly comparable. No new particles, shaders, render targets, per-prop nodes or per-frame texture creation were introduced.

## Install

Back up your current deployment and persistent data. Install the complete Server Update into the existing server project while retaining environment/secrets and persistent data, then restart on V244 before replacing the static Web files with the complete Web package. Keep the established hosting and security-header configuration; serve over HTTP(S), then hard-refresh clients. The release stamp is `V244-street-details`; application version is `244`.

The Editable archive contains the complete Godot 4.5.1 project, accepted originals, references, prompts, deterministic preparation script and QA evidence. Allow asset import before running in the editor. This update does not migrate or reset player data.

Native day/night, Chromium/WebGL2 rendering, production Web boot and server import/compile were checked. Physical school-device benchmarking and live multiplayer/account connectivity remain untested; local static browser preview has no deployed account backend. See `VALIDATION_V244.md` for evidence and limits.
