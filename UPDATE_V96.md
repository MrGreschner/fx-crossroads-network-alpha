# v96 — discover the Crossroads

- Main menu now rotates through four sets of six heroes and four sets of six enemies: 24 unique entries on each side. Sets change every 12 seconds. Longer names wrap onto two lines.
- All 72 heroes have a short lore entry under **Story**. Existing playstyle summaries remain visible. Lore identifies unusual characters such as Patch the awakened controller and Mosaic Tender the axolotl gardener.
- The Character Hall shows compact colour-coded cards in this order: Primary, Secondary, Passive, Special. Each card shows its input, unlock level, name and quick effect summary. Click/tap the card to expand or collapse the full explanation and cooldown. Mastery follows these four cards.
- Choose a Realm shows discovered enemy and boss names under their portraits. Unseen entries retain question marks and **Unknown** labels.
- The east-bank quest forest is now a grove with a marked through-trail, a separate Chimehouse branch and a deeper camp clearing. The campfire, resting traveler, benches and lettering have separate space. Tree trunks match their collision areas; the quest route stays open.
- Menu gallery animation redraws at up to 30 Hz and stops when hidden. Art, wrapped captions and forest tree positions are prepared once. Offscreen forest drawing and distant forest collision checks are skipped. All v95 terrain caching and idle-save improvements remain.
- Fixed an existing unsupported numeric-format token in full descriptions of slowing abilities.

Hero numbers and internal IDs remain unchanged from v95. No room-server change is required.

## Student metadata

`content/hero_library.json` stores each hero's gameplay `summary`, short `lore`, and `passive_brief`. Add these when creating a new hero. Keep summaries short; save longer explanation for the hero's existing ability descriptions.

An attack may optionally include `ui_brief` for its compact card. Otherwise `scripts/hero_library.gd` derives a quick summary from its style and damage fields. The complete description still comes from the usual ability data.
