# V240 artwork sources

Mode: reference-guided image generation using the built-in imagegen tool. References: the existing V232 mine entrance and prior Cave Descent entrance. Four new original, transparent-background props preserve their town identities: slate cave, timber-and-stone Exchange, stone fountain and green iron street lamp. No third-party asset pack was used.

Accepted full-resolution source images are assets/town240/*_source.png. The four original generation prompts are tools/town240_prompts.json. Exchange received one silhouette/background cleanup pass: preserve all design, proportions and shading; remove exterior haze, glow, drop shadow and stray pixels; use crisp transparent pixel-art edges. The original lamp was accepted; a cleanup attempt returned no image and was not used.

Runtime: tools/prepare_town240.py alpha-crops at alpha ≥230, resizes with nearest-neighbour sampling and writes one 1024 × 512 atlas and region manifest. The original source alpha is retained. These sources are for editing; runtime uses only the atlas. Fountain water and lamp/window illumination are code-native effects, not baked light halos.

Dust Marshal uses the existing native walking rig in hero_walk222.gd. Two alternate-leg poses were baked into the existing shared runtime atlas, retaining his idle upper body and established neutral facing. tools/export_dustmarshal240.gd documents the source-frame generation.
