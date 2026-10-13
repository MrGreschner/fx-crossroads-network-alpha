# v146 — Build worlds and submit practical evidence

## Crossroads Studio
The public Studio is now a larger six-lab campus. Its entrance and reserved landscaping move with the expanded building; the Academy remains separate.

- **Hero Workshop:** Artwork → Alternate Forms → Add form. Draw or upload an extra PNG, then choose it under an ability's **Transform into** selector and set a 0.2–8 second duration. Four forms maximum. Held flame channels maintain the form while held. The normal pose returns afterwards. Mastery abilities can use a form too. Forms are visual changes; their appearance does not change collision, movement, immunity or stats.
- **Finalize & Play** saves/installs a hero into the Custom Hall and enters Training Yard immediately. Official hero attacks and artwork are unchanged.
- **Object & Raster Lab:** 32 starter objects including trees, plants, benches, lamps, fences, bridges and buildings. Draw or upload PNGs; set display dimensions and movement/projectile blocking separately. Save up to 20 objects. Five starter examples and a visible Clear / Start fresh button.
- **Raster Studio:** up to four editable layers, layer ordering/visibility, rectangular selections, hex colours, gradients, patterns, tone correction, non-destructive alpha masks, custom brush capture/stamping, document sizes and editable source metadata. PNG exports are available separately. The JSON retains layers, masks, brushes and recorded operations. Importing a new flattened PNG replaces the previous layer stack deliberately.
- **Realm Builder:** enter dimensions first (8–48 tiles each way; tiles are 40 world pixels), paint terrain, draw custom tile PNGs and choose walk/projectile blocking separately. Place saved props and enemies, or Grove practice presets. Up to 150 placements, 24 enemies, 32 object types and 12 enemy types. Set spawn/exit. Five example maps include a Bramble encounter.
- **Finalize & Play** checks spawn, exit and a connected route, saves the realm and opens a scrolling battle test using your Workshop hero. WASD / touch movement, LMB / RMB / Space attacks; mobile attack buttons are available. Reach the gold exit. Enemy decisions and attacks use the existing bounded Studio interpreter. Tests award no XP, gold, mastery or trophies. End test returns to the builder and records a short summary. These custom realms are local Studio tests, not new public multiplayer match types.
- All project types have a finalize/save action and Student Mode submission controls. Finalization makes usable local work; submission freezes a separate copy for teacher review. Hero, ability, enemy and behaviour submission actions finalize and submit together. Object/realm submission is enabled after finalizing the current revision.

## Portable work
Download individual hero, ability, enemy, behaviour, object or realm JSON files to share. Use the matching Lab's Import button or Studio's Open project. A player profile ZIP includes the `objects/` and `realms/` folders alongside previous creations. Unfinished Object/Realm drafts are backed up under `studio/` too. New Game clears those local drafts as well. Imports are bounded data with validated images and references; no imported script files execute.

Existing live Partner Up supports hero/ability/enemy/behaviour projects; alternate hero-form pixel edits participate in that workflow. Object and Realm projects can be shared as files; this release does not add concurrent world editing.

## Practical assessment
An attached artifact supplies evidence of practical tool use, production and file settings. Those outcomes no longer require a second tool-use essay. Short responses remain for initial vision, conceptual comparisons, permissions, critique and decisions that the artifact cannot show. Existing journal history/submissions are retained for import and review. Business simulation reports and tested IPO programs also replace repeated descriptions of their mechanics.

The teacher view shows flattened artwork, editable layers, recorded operations, map layout, initial vision, test summaries and frozen source. Submitted realms can be explored with a practice hero without installing or modifying the student's or teacher's project. Readiness/suggested scores reflect evidence presence, never automatic course credit or verified originality. Teachers assess actual quality and correctness. Local timestamps/order are editable and do not prove independent authorship.

New modules:
- **DES2035 — 2-D Design 2:** record a realm vision before production, draw three matching props, build and test a realm, present a short critique.
- **COM2035 — Raster Graphics 1:** three coordinated props with layered source, selection, gradient/pattern, mask and output metadata; credits and a brief presentation caption.
- **COM3035 — Raster Graphics 2:** four coordinated props, custom brush, correction, layered masks/selections and before/after proofs; credits and a brief critique.

These are screen-raster assignments aligned to the supplied main outcomes. Full channels/CMYK/HDR/print workflows are not implemented in Crossroads; instructors must request appropriate external source/work for those technical requirements before assessing the full detailed course.

## Stability and checks
Realm terrain and collision use a spatial index; the camera culls off-screen props and tiles. The new labs fit desktop and small landscape viewports. Alternate forms are cached once and network snapshots send only form identifiers/duration, not PNGs every frame. Profile ZIP integrity/restore and official-game regression checks are included in the release tests.
