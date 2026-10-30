# V241 original landmark artwork

Mode: built-in imagegen, reference-guided style transfer. Four generated sprites replace the town facades of Studio, Academy, Gladiator Arena and Challenge Lodge. Identity references are their own prior V240 game facades. Material/style reference is the accepted V240 Exchange artwork. No outside asset pack is used.

Full prompts: tools/town241_prompts.json. Original accepted transparent images: assets/town241/{studio,academy,arena,lodge}_source.png. Runtime atlas and region/glass coordinates: assets/town241/landmarks.png and landmarks.json. Source images are editing material and are not included in the runtime pack.

Rebuild: python tools/prepare_landmarks241.py (Pillow). Alpha ≥230 determines crop bounds, original alpha is preserved, and nearest-neighbour resizing produces four shared texture regions on a 1024 × 768 canvas. Regions use the original facade world envelopes; doors, collision and access logic remain in their original scripts. No runtime baking is required. Game-rendered signage stays legible and avoids baked lettering. Night illumination uses hand-fitted individual glass panes and existing bounded local light rendering.
