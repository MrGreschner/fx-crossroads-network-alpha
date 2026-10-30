# V242 artwork provenance

Original raster artwork was created with the built-in image-generation tool using each existing facade as the identity/composition reference and the accepted V241 landmark atlas as the material/style reference. Every building has its own prompt and image; the two existing matching arcade structures share their booth frame while preserving separate product displays.

- Accepted generated originals: `art_sources/town242/generated/` (24 images).
- Existing facade reference renders: `art_sources/town242/references/`.
- Style reference retained unchanged: `assets/town241/landmarks.png`.
- Full prompts, including the rejected Market background-removal attempt and accepted regeneration: `tools/town242_prompts.json`. The accepted Market is `market_final`; its image is `generated/market.png`.
- World/sprite envelope and entrance records: `tools/town242_layout.json`.
- Offline atlas and fitted glass-mask preparation: `tools/prepare_shops242.py`.
- Prepared runtime atlases/manifest: `assets/town242/`.
- Offline native architecture baking: `qa/v242_bake.gd` and `qa/v242_bake_canvas.gd`.
- Runtime facade, sign and glass renderer: `scripts/town_shops242.gd`.

References reconstructed from in-game procedural renderers may contain a small UI badge; prompts explicitly excluded it. Baked production caches hide that UI and contain no badge. Original full-resolution artwork is retained for editing and is not loaded or included as new source art in the Web PCK or Server Update. No existing V241 artwork was regenerated.

To reproduce preparation, run `python3 tools/prepare_shops242.py` in the Editable project. Regenerate the three architecture caches with Godot 4.5.1 and `qa/v242_bake.gd` in a compatibility-renderer session. QA scripts from this development session have explicit output paths; change those output destinations when running elsewhere. These developer fixtures are not normal gameplay entry points.
