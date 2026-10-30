# Crossroads: Realms Beyond — V246

Completed update based on V245. No deployment was performed.

## Fixes

* Melee and ranged town guards now stand 62/64 world pixels high, with the same artwork, foot anchors and patrols.
* Neighbour visits use separate clear meeting positions. Four visitors to Cliffside Cottage meet in its side lane, clear of the Academy's decorative roof. Weekly job, leisure, event and bedtime schedules remain intact. These visits intentionally pause for conversation; path sampling confirms movement and subsequent departures.
* Resident-state caching follows calendar changes, including a resumed session or development time preview, without per-frame string construction.
* Cliffside Cottage moves 22 pixels north. Its complete facade, collision, doorstep, approach, mailbox, chimney, windows and emission mask move together. The result leaves clearance from both the Academy roof and Cave Descent court. Other buildings stay in place.

## Town artwork

A jagged slate-and-moss western mountain formation connects visually into the existing mine and cave rockwork. It stays clear of the Challenge Lodge. Mine and cave mouths, rail centreline, collision and service access are unchanged. The mine-to-Deepwell Exchange railway gains detailed sleepers, rail heads and fasteners. Cave Descent's existing pillars receive carved stone treatment.

The wishing well keeps its circular stone basin, timber windlass, rope, bucket and blue slate roof. Community Records retains its timber kiosk and three parchment sheets, now with a ram crest. Both keep their original services and interaction points.

The large single yellow grass flowers are replaced by sparse, deterministic clumps of six wildflower variants. Hashed offsets avoid rows and repeated cell-centre placement; routes, reserved lots and blocked ground are rejected. Realm scenery flowers remain unchanged.

Wayfarer's Rest, the existing fountain and Town Notices now form a paved secondary court, with a fountain roundel, paired seating and low planting beds. Seats stay clear of street centreline routes. Existing pavilion, fountain, notices, fishing shop and meeting locations stay in place. Paving is focused on this court; a broader grass/path/water texture pass can follow independently.

## Cultivation

All 80 growable species, including the twelve Giant Growers Fair crops, have revised editable artwork for seeds, young plants, mature plants and harvested produce: 320 frames. Each retains its established species silhouette, branching, palette and botanical motifs, with coloured edges, matte planes, leaf veins and restrained surface detail. This is a native SVG refinement, not 80 new AI-generated illustrations.

The town beds and gardening interface share the new frames. Young plants advance to a tinted fruiting appearance at 55% of their existing elapsed growth time, then their original ripe colours at the original completion timestamp. No timers, crop definitions, yields, levels, currencies, seed counts, produce counts, recipes, care rules, XP, fair seasons or save formats change.

## Installation

Back up your server configuration and persistent data. Install/restart the complete V246 Server Update before installing the full V246 Web package. Preserve environment variables/secrets and persistent player storage. Editable is the complete Godot 4.5.1 project. Nothing has been deployed by this update.
