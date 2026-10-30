# V246 artwork sources and rebuilding

New ridge, well and records kiosk: built-in image_gen with genuine transparency; original files, SHA-256 provenance and exact prompt strings are in `art_sources/town246/`. Their bounds are cropped and fitted with nearest-neighbour sampling when building the runtime atlas. A foothill region reuses the lower part of the ridge original. Originals are preserved.

Railway, stone pillars, court and wildflower clumps: editable native SVG under `assets/town246/vector/`. Their preparation source is `tools/prepare_scenery246.py`.

Crops: all 80 botanical silhouettes from the established `tools/build_botanical_art.py` are refined by `tools/prepare_garden246.py`. All 320 editable final SVGs are in `assets/garden246/vector/`; catalogue and original ID-to-form mapping are in `catalogue.json`. This preserves each crop's design rather than substituting a shared generic fruit.

The scene atlas is 1024×1129 RGBA (4,624,384 decoded bytes). Crops are eight immutable pages of 1056×580 RGBA (2,449,920 decoded bytes each). Pages load only on first request; frames and textures are cached. Viewing one crop does not load the entire catalogue. All pages together are bounded at 19,599,360 bytes. There are no new shaders, particles or per-frame texture uploads/creation. Wildflowers are built once into retained terrain chunks, with a shared overlay pass per chunk. The existing cave courtyard remains in its original cache and is never repainted over that layer.

Offline authoring sequence (Python 3 + Pillow and Godot 4.5.1): run `tools/prepare_garden246.py`, then `tools/prepare_scenery246.py`; use `qa/v246_raster.gd` with Godot headless to rasterize `res://assets/garden246/vector/` into WORK/crops and `res://assets/town246/vector/` into WORK/scenery. Run `python tools/pack_art246_reference.py ABSOLUTE_WORK_DIRECTORY`. The accepted generated originals are read from this project. These tools change artwork only; use the normal verified release process afterwards.

V245 item/relic originals and their provenance remain included without modification. The older lost exact relic-generation prompt file remains unavailable, as documented in V245.
