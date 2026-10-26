# V215 artwork and frame preparation

Created with the built-in image-generation tool from the game's V207/V208 style references and current designs. No third-party packs were added. Two six-pose sheets: Crosswind Striker and Caelum. Seven four-pose sheets: mini basketball, Bit Buddy, two different wooden puppets, ram guard, ram miner and Bramble. The main-menu town background is a separate wide matte pixel-art image. Generated art is modest, coarse and readable, with selective coloured contours rather than black sticker outlines.

Originals are retained as assets/hero215/*_source.png and assets/art215/*_source.png; the background is assets/art215/menu215.png. Runtime loads only the extracted 80×80 frames and background, using cached textures. Source sheets are excluded from the packaged web and server. Full style and design notes are in Art_Prompts_V215.md.

Run tools/prepare_art215.py from the editable project to regenerate frames; it uses Pillow, NumPy and SciPy. It detects transparent gutters and anchors each main body rather than loose particles. tools/art215_mapping.json refers only to retained local source artwork. The script is idempotent. tools/align_walks215.py aligns Mara/Aurel movement B to idle without regenerating their appearance; pre-fix frames are retained as *_walkB_before_source.png.

Gameplay effects use scripts/combat_art215.gd: bounded immediate-mode geometry, no particle nodes/fullscreen shaders/per-frame image decoding. See scripts/minion_art215.gd for four-state summon animation selection and bounded motion/texture caches. Frame source positions and factors are in assets/art215/manifest215.json.
