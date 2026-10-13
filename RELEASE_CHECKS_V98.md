# v98 validation

Checked locally with Godot 4.5.1.

- tests/v98_heroes.gd: all assertions passed. Both heroes/assets register; mastery buttons affect different slots; front-only fright and wall blocking; stun-then-slow timing; fireball impact/burn; critical bonus versus chance and earned tier; healing multiplier; both treat landings; all five field effects, lifetimes and effect cap; pincer damage; four-shot capture limit/expiry; bank defence; wall-safe scuttle/counter shards; all base and mastery cast routes; allied/rival aura filtering and nonstacking; guest attack authority, host movement protection and serialized/received visual effects.
- tests/v97_additions.gd and tests/v97_refinements.gd: passed, preserving previous arena/cosmetics/town/combat refinements.
- tests/v96_polish.gd: passed gallery, compact cards, lore and encounter UI checks with the expanded roster.
- tests/v95_maintenance.gd: passed numbering, settings, bounded route caches and Gate Defence pressure checks.
- tests/v90_combat.gd: all assertions passed for earlier kits, mastery casts and network authority.
- Godot native render inspection: both Character Hall entries, pumpkin/scary-face art, airborne treats, field icons, candle aura, crab claws/captured-shot shield and damage-reduction display.

The existing single retained-resource warning appears when the party/arcade headless test scenes shut down; no failed assertions or runtime script exceptions occurred in final tests. Local native/headless tests do not substitute for testing classroom browsers, phones and an actual online match.

Room service files are byte-identical to v97. Protocol remains 26.
