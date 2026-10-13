# v97 validation

Checked with Godot 4.5.1.

- `tests/v97_additions.gd`: passed arena fade/repeated-status handling, manual/live and automatic respawn scoreboards, cosmetics lock/equip/close behavior, modern Elder guidance, four-second Veil and pond shoreline/tree/path separation.
- `tests/v90_routes.gd`: passed town routes with upgrades built after the pond/hill changes.
- `tests/v93_menu.gd`: passed menu/profile flow.
- `tests/v88_party.gd`: all party and leaderboard assertions passed; its existing single-resource shutdown warning remains.
- `tests/v97_refinements.gd`: passed. Top-button alignment/style and points state; Tova tongue reach and passive rate/level/DoT rules; smooth Hogtie proximity, stun and wall blocking; Mantis cone boundary; exact smoke chance, stationary lifetime, friendly/rival filtering and guest snapshot; distinct wing poses; capped/expiring trails; boss ordering across the catalogue; difficulty colours and lobby text inset/centering.
- `tests/v90_combat.gd`: all assertions passed for original kits, mastery casts, summon caps/lifetimes, feather banking, host-owned guest movement and effect snapshots. The previously observed single retained-resource warning remains at headless test shutdown.
- `tests/v92_battlegrounds.gd`: all assertions passed for barracks, units, upgrades and host-owned army effects. Its existing retained-resource warning occurs at headless shutdown.
- `tests/v94_polish.gd`: passed lobby team choices, host preview and co-op selector separation.
- `tests/v95_maintenance.gd`: passed numbering, favourite icons, terrain/route caches, settings and Gate Defence pressure.
- `tests/v96_polish.gd`: passed four gallery sets, all 72 compact ability/lore entries, enemy captions and forest/camp layout.
- Rendered and inspected aligned normal/points buttons, named Astral Rift portraits and separate boss section, Arena/co-op lobby layouts, Cook/Mantis/Tova hit graphics and the Cindervane smoke field. Also inspected the revised pond and ram sprites, cosmetics buttons, Elder topics, compact arena notice, clear arena after fading and manually opened leaderboard. No script exceptions in the final rendering run.

These are local headless/native checks, not a physical phone or live classroom multiplayer test. Re-export and test your usual devices before students join. Room service protocol stays 26; no Render configuration/service update is required for this release.
