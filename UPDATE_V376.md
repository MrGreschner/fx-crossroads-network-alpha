# V376 — Training yard landscape and clear hero ownership

Complete release based on V375. This update changes the training yard presentation and hero-selection access. Ownership stays at schema/EPOCH 4: no new reset, grants or changes to existing requirements.

## Training yard

- Restored textured grass around the outskirts, with rounded, softly worn boundaries against a connected earth approach, outpost courtyard and main practice field.
- Kept three related materials: grass, muted gravel/earth and a single timber work area under the existing benches and supplies. No cobble mosaic or extra competing ground patches.
- The path reaches the existing return-gate position and continues towards the outpost, hero book, allied target and practice area. Two decorative supply props were aligned with their supporting surfaces.
- Reuses the existing game's pixel textures and props. A retained ground surface handles the blend; there are no new full-map raster textures or physics changes. Targets, launchers, moving-target route, colliders, hero scales and walk-out exit are unchanged.

## Character Hall

- Unlocked: original coloured portrait, teal card and green check badge.
- Unlock mission available: warm gold card, gold border/side stripe and mission diamond. This follows real eligibility: home-realm victory for champion duels, existing journey prerequisites for courses, or the immediately available guided Teacher project. Activity-only goals continue to show their real requirements rather than claiming to have an instanced mission.
- Locked: muted, desaturated portrait, subdued card and padlock. Inactive event heroes remain unavailable.
- Applied this visual language to both scrolling rows and the portrait grid. Removed the appended Locked text from row titles; added a compact legend, explicit unlocked count, matching detail status and a gold mission button when actionable. Locked cards remain inspectable for story, abilities and requirements.
- Locked heroes' Test buttons are disabled. The callback, direct training entry and direct practice-run entry all check ownership before mutating the current run. Only unlocked, active heroes can train. Viewing a locked portrait does not change the selected playable hero.
- Custom Studio projects and approved community heroes keep their existing access. Authored unlock journeys can still provide their temporary course kit; this does not unlock the hero or permit ordinary training.

## Validation

Godot 4.7.2 checks passed for nine starter heroes, all ownership states and real realm/journey/event eligibility; desaturated portraits preserve transparency and proportions; list/grid styles, gold borders, badges and counts; blocked Test callback and blocked direct training/practice calls with unchanged position/health/inventory; immediate access after a genuine champion award; retained floor visibility and unchanged collisions; actual event journey loan without a training bypass. Native rendered yard, practice field, list/grid, ready/locked detail panes and compact 960×540 layout were reviewed. V375 Lockjaw/Nutcracker/Frost combat tests passed again using earned-hero test fixtures. Existing resource cleanup warnings at process shutdown persist. Live browser/mobile/Render testing has not been performed.

Full ZIP CRC, no duplicate entries, all changed source bytes, web part offsets/sizes/hashes, assembled game-data hash and packaged-script loading are checked during packaging. Every individual file in Web/Server packages is below 100 MB; game-data parts are at most 32 MiB.

## Complete packages

- Crossroads_v376_Web.zip — full web game. Extract all contents for the web host.
- Crossroads_v376_Server_Project.zip — full source/artwork/server repository, including project.godot, Dockerfile.network and network_service. Copy extracted CONTENTS into the existing GitHub Desktop folder, replacing matches while retaining .git and Render environment/database settings; commit and push. Do not commit this ZIP or an exported .pck.
- Crossroads_v376_Editable.zip — full editable Godot project. Open Crossroads_Realms_Beyond/project.godot.

No patch scripts or older release downloads are needed. Web V376 is required to see the new Hall and yard. This presentation/training-access update does not change protocol 11, server ownership epoch 4 or the database schema; V375 server compatibility remains. The complete V376 server package includes all current V375 combat fixes for a matching full deployment. Keep V375 as rollback.
