# Crossroads: Realms Beyond — V243

Step 3: homes and vegetation. Built from the completed V242 packages, preserving the V241 grand landmarks and V242 shops/public buildings. No deployment performed.

## Artwork

Six homes retain their distinct silhouettes, roof colours, entrances and individual details: green-roof Cliffside cottage, purple-roof two-door Willow Court duplex, red-roof Orchard home and produce bin, blue-roof Guard townhouse and crest, teal-roof Reedbank porch home, and the smaller weathered timber Tidekeeper cottage. All retain their original art canvas sizes and world locations.

Twenty prepared artwork frames cover those homes, ordinary pines, ancient broadleaf trees, blue Starlace, Amber Willow, apple tree, marina knot willow, two flowerbed arrangements, reeds, shrubs, communal sprouts/blossoms, empty planted-bed frame and pond lilies. Soft coloured edges, matte shading and readable clusters follow the accepted V207/V208 character style; existing hero sprites remain unchanged.

Window glass masks are fitted to the new panes, including both duplex doors. Chimney smoke starts at the new chimney positions. Tidekeeper's two existing window lights follow the new glass. Starlace keeps its eighteen live glints, now placed on its leaf clusters; the marina willow keeps both live hanging lanterns at their original positions. Trees and reeds use a dephased sway of at most one world pixel with fixed root vertices. Apple shake/drop, fruit interaction, gardening states and harvest logic are retained.

## Navigation and performance

No building footprints, wall collision rectangles, door/interaction points, roads, tree roots, service logic, NPC routes or progression rules were changed. Two immutable runtime textures add 5 MiB of decoded RGBA storage: a 1024×1024 art atlas and a 1024×256 glass atlas. No new nodes, particles, shaders or render targets implement the sway; each visible tree is one textured quad. Existing cached ground pages are reused with UV rectangles split once around replaced plant paint. Street props and the town layout remain in place for step 4.

## Install

Use the complete Server Update package for the existing server project, retaining your environment/secrets and persistent data. Restart the server on V243 before replacing the static Web files with the complete Web package. Serve over HTTP(S), using the existing hosting configuration. Hard-refresh clients after updating. The Editable package opens in Godot 4.5.1; allow the editor to import assets before running. Runtime and source packages include version V243 / V243-homes-vegetation.

The packages have been built and checked locally. Native Godot Compatibility rendering was inspected by day and night. Actual browser and school-device testing has not been performed in this environment.
