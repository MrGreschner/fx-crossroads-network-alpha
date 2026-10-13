# v95 — maintenance and classroom readiness

- Favourite stars in the Character Hall use vector icons, avoiding missing font glyphs. The selected hero is highlighted in gold.
- All 72 heroes are numbered consecutively in the authored roster order. Harbor Bell is 20; Polarity is 21. Filtering and favourites keep a hero's roster number. Internal hero IDs remain unchanged.
- The Profile / Mastery / Town shortcut has a brighter teal fill and gold outline.
- Main menu and pause menu include Options: 30 / 60 / 120 FPS, school performance mode, sound, local diagnostic recording and report download. Settings stay on the current device. School mode sets 30 FPS; turning it off sets 60 FPS; a different cap can then be selected.
- Town/world terrain tile classification is cached between world loads, with a bounded cache. Patrol routes and segment lengths are prepared once. Unchanged mastery/profile data is no longer written repeatedly. Hidden main-menu gallery animation stops, and the game does not redraw the world beneath the opaque title/options pages. Live multiplayer simulation still continues while a menu is open.
- North Gate starts with 19 / 28 / 39 enemies for 1 / 2 / 3 players. The second wave arrives after eight seconds. Guard reinforcements come every 24 seconds, with an eight-per-lane base cap; upgrades still improve the army. Unupgraded guard strength grows more slowly and creeps are sturdier. Two base soldiers and one surviving-outpost soldier per lane remain. Enemy entrances, outpost checkpoints, player scaling, guard speed and wave-30 boss remain intact.

The performance work reduces repeated CPU work; it is not a guarantee against browser graphics-driver crashes. Keep diagnostics available for classroom testing.
