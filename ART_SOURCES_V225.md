# V225 art provenance

Five game sprite sheets edited with the built-in image generation tool using the existing V224 six-pose hero sheets as identity references and Young Ram/Rune Duelist as style references. No external asset packs used. Prompts are in tools/hero225_prompts.json. Original selected RGBA sheets are preserved in assets/hero225/*_source.png; normalized runtime frames and crop/scale metadata are alongside them.

Lyra required two targeted corrections to remove an extra hand and keep the staff on its established side. Only the corrected selected sheet is used by the game. No new runtime shaders, large textures, per-frame image generation or downloads were introduced. Gameplay loads five six-pose sets of 80x80 sprites and caches them using the existing pipeline. Neutral movement is cached once from the idle sprite; foot/paw rectangles are in scripts/hero_walk222.gd.

Crosswind Striker and Alderjaw are size-only changes using original art. The cat's previously raised tail was mistaken for a hat on the roster sheet; the new silhouette preserves an actual tail curled lower behind the head.
