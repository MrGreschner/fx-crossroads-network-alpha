# V214 artwork and frame preparation

Ten six-pose sheets were created with the built-in image-generation tool using the current hero designs, lore, ability definitions and V207/V208 style references. No third-party asset packs were incorporated. Identities: Tumblebrew (porcelain teapot); Rook Ironhand (bridge keeper, brass gauntlet/chain); Alderjaw (beaver); Iris Chalkbinder (tutor/chalk); Bolt Ironcore (reclaimed iron robot); Cloudloom (robed weather wizard); Cairnheart (badger stonecarver); Caelum Mirrorwright (visor, copper braid, hand mirror); Dustdevil (brass vacuum); Merrymask (wooden theatre puppet).

Rook has dark brown skin and Iris has medium brown skin, as requested. Outfits, equipment, species and abilities remain distinct and lore-informed. Full prompts are in Hero_Prompts_V214.md; the reusable style prompt is Crossroads_Hero_Art_Style_V214.md.

Originals are retained as assets/hero214/*_source.png in the editable project and excluded from web/server runtime bundles. tools/prepare_hero214_art.py regenerates the six small transparent frames and root compatibility poses using Pillow, NumPy and SciPy. It detects the actual transparent gutters, rejects clipped neighbouring-cell fragments and anchors the visible main body to the shared foot baseline rather than anchoring to loose effect particles. Per-hero display factors continue the V213 sizing rules.

Reed's existing capybara art is preserved. tools/align_reed_walk214.py corrects only movement B: removes 14 isolated stray pixels, shifts its body 7 pixels right and 11 down, and updates compatibility walking aliases. It is idempotent. The original sheet remains available. No generated redraw is used for Reed.

Runtime uses 80×80 cached frames and draw-rectangle scaling. No full source sheets are decoded during gameplay. Existing attack, projectile, range, damage, collision and network rules are unchanged.
