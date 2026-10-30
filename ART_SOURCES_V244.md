# V244 artwork sources

Built-in image generation was used for all twenty-eight new prop illustrations, with each object's own V243 design as the edit reference and `assets/ram_idle.png` as the accepted V207/V208 style reference. Original hero and NPC artwork remains byte-identical.

- Accepted originals: `art_sources/town244/generated/`.
- Original render references: `art_sources/town244/references/` (including a native courtyard underlay for the postal cart).
- Original cache pages for reproduction: `art_sources/town244/cache_baseline/`.
- Full prompt set and relative source mapping: `tools/town244_prompts.json`.
- Preparation: `tools/prepare_streets244.py` (Python 3, Pillow and NumPy).
- Runtime atlas/metadata: `assets/town244/street.png` and `street.json`.
- Recorded local cache substitutions and pixel-preservation evidence: `assets/town244/cache_edits.json`.
- Renderer: `scripts/town_streets244.gd`.

The preparation script performs alpha bounding, nearest-neighbour fitting, explicit bridge-rail fitting, atlas packing and compositing into recorded existing scenery-cache regions. It does not create illustration content. Both bridge variants derive from the same accepted illustration; their fitting preserves the original deck edges. Existing V243 flowers are reused in three remaining garden islands, without another runtime texture. Original generation files are editor-only and do not enter the Web PCK.

All physical geometry, service logic and schedules remain in their previous owners. The original renderer functions call the cached frames; existing text and light/effect code remain live. The two sign-fit corrections are recorded as rectangles in the new renderer, leaving approved building illustrations and their metadata unchanged.
