# V245 artwork provenance and rebuild

21 accepted relic originals were recovered from the preceding image-generation session, without regenerating their artwork. They were produced with built-in image_gen using the V207/V208 Ram for style, soft coloured edges, matte shading and readable pixel clusters, and preserving each relic's silhouette/theme. PNG originals and their supplied alpha remain intact.

`art_sources/items245/provenance.json` records the exact Library filenames, IDs, accepted relative paths and SHA-256 hashes. Originals: `art_sources/items245/generated/`. Style reference: `art_sources/items245/references/V207_V208_Ram.png`. The exact prior prompt file was lost with the temporary workspace; provenance does not claim that file was recovered.

The established native SVG/code system was refined directly for normal items, foods, rods, gear and bait. Editable results: `assets/items245/vector/`; original design-source mapping: `assets/items245/native_sources.json`. All original source assets remain in their unchanged V244 paths.

Rebuild from the project root:

1. `python3 tools/prepare_items245.py` creates 106 native SVG frames.
2. Godot 4.5.1: `--headless --path . --script res://qa/v245_native_raster.gd -- /absolute/native-raster-folder`.
3. `python3 tools/pack_items245.py /absolute/native-raster-folder` (Pillow required).

Runtime artwork uses only `assets/items245/items.png` and `items.json`. Fitting uses transparent atlas placement and nearest-neighbour reduction; generated originals are unchanged. Held-rod body endpoints are (12,64) and (116,64), transformed to the existing original hand/tip anchors.
