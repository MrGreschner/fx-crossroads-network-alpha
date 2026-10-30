# V247 art sources

Six built-in image-generation sources are retained unchanged with their exact prompts and SHA-256 provenance in art_sources/town247. These supply grass, path, water, and the three distinct portal frames. Existing V207/V208 references and the V246 project supplied the visual direction: soft coloured edges, matte shading, readable clusters and preserved identities.

The accompanying tools prepare civic paving, ripple and energy/rune SVGs, rasterize them offline, and pack transparent PNG atlases. Normalization uses nearest-neighbour scaling, source-bound cropping and atlas placement. Portal energy and rune effects are pre-rendered. Runtime rendering creates no image per animation frame and uses no extra lights or shaders for this update.

Main atlas decoded budgets: ground 870,400 bytes; civic paving 627,200; portals 5,087,232; water and ripples 589,824. Surface-cache siblings retain original page dimensions and UVs. Original cached art is retained; sibling sheets reveal water only inside original water shapes and recolour original soil/forest regions. The market's sibling sheet changes only its three existing flat yard colours. Other realms' water is outside this update.
