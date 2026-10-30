# V243 artwork sources and reproduction

Accepted source originals: `art_sources/town243/generated/` (twenty PNGs). References: `art_sources/town243/references/`. Full prompts: `tools/town243_prompts.json`. Original position, canvas, wall, door and inset record: `tools/town243_layout.json`.

Generation used each object's own previous design, the accepted V207/V208 ram sprite, and completed town artwork as appropriate. Each output was reviewed and prepared for its existing canvas; no hero or NPC artwork was replaced. These originals are editor-only and do not enter the Web PCK.

Run `python3 tools/prepare_nature243.py` from a Python environment with Pillow and NumPy to reproduce `assets/town243/nature.png`, `glass.png`, and `nature.json`. This script performs deterministic alpha cropping, nearest-neighbour fitting, atlas packing and fitted glass/chimney/glint annotation. It does not draw or regenerate illustration content. Generated art remains in the originals.

The runtime helper is `scripts/town_nature243.gd`. Existing renderer owners request its frames; collision and behavior stay with their original owners. No runtime image editing or per-frame texture upload is involved.
