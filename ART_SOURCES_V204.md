# V204 core-hero artwork and animation

All four original sprite sheets were generated with the built-in image generation tool, using the approved charcoal-cat/navy-ram pixel preview as the reference. The game uses small cached PNG frames; no per-frame image generation or new lighting nodes are involved.

## Files

- Approved design: tools/core204/approved_reference.png
- Original transparent art sheets: assets/core204/ram_source.png, cat_source.png, book_source.png, elder_ram_source.png
- Normalized game frames: assets/core204/<hero>_00.png through _11.png; Elder has00–07.
- Frame extraction metadata, source bounds and baseline: assets/core204/frames.json
- Optional extraction tool: tools/prepare_core204_art.py (Python, Pillow, NumPy, SciPy).
- Cached runtime textures, walking cycles and special-ability pose selection: scripts/core_hero_art.gd

## Final generation prompt set

Shared requirements: production transparent coarse pixel-art sheet using the approved character column as the visual reference; crisp square pixel clusters equivalent to roughly48x64 source pixels, only2–3 shading tones per material, modest detail, no painted fur, no labels, scenery, cast shadows or backgrounds. Equal-sized cells, complete bodies, consistent scale and baseline, generous transparent margins. Preserve each approved character, not a new redesign.

Young Ram:12 poses in4 columns/3 rows. Cream wool, tan curled horns, navy tunic, small belt, brown hooves. Row1 idle, left-hoof-forward walk, passing walk, right-hoof-forward walk. Row2 opposite passing walk, headbutt windup, headbutt strike, low horn-first charge. Row3 Earthshaker raised-hoof windup, stomp impact, recovery, relaxed breathing idle. No cape/scarf.

Crossroads Cat:12 poses in4 columns/3 rows. Dark charcoal tabby, small cream muzzle/paws, teal eyes, purple scarf, curling tail, four-paw animal silhouette. Row1 idle, trot stride, gathered trot, opposite stride. Row2 opposite passing trot, raised-forepaw swipe windup, forward swipe, curled Whirlwind Spin. Row3 opposite spin, Shadowstep crouch, low launching stealth run, over-shoulder idle. All bodies opaque; existing game transparency handles stealth.

Living Book:12 poses in4 columns/3 rows. Upright floating plum/brown leather volume, ivory pages, gold corners/eyes, red bookmark, no human limbs. Row1 idle and three tilting/rising hover phases. Row2 fourth hover, Paper Cut windup/strike, Flying Pages open pose. Row3 alternate page flutter, Spellbeam opening windup, open release with compact cyan-white glint between pages, closing recovery. No beam extending outside the sprite; existing gameplay draws it.

Elder Ram:8 poses in4 columns/2 rows. Approved cream wool/beard, tan horns, muted green robe, brown belt and wooden crook. Row1 idle and three slow staff-assisted walking poses. Row2 opposite passing walk, open-hand talking gesture, nod/blink, greeting. Keep the green outfit; no navy recolour.

Sprite slicing is technical preparation: retain connected character pixels and detached page/scarf components, fit each character family with one shared scale onto an80x80 transparent canvas, and align feet/page baseline at74px. No replacement artwork was painted during slicing. Character stat JSON is unchanged.
