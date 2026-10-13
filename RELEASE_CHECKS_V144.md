# v144 checks

- 44 Foundry assertions: depth gates, production, recipes, furnace exclusivity, offline completion, refunds, construction materials, one-time reinforcement, old-mine furnace access, validation, old Market migration, bar sales and Playtest restrictions.
- 22 runtime assertions: direct Adventures navigation, all Mine/Market tabs, small landscape panel bounds, player ZIP export, exact path results, index invalidation, saved JSON and empty-list safety.
- 49 existing Mine assertions passed, including offline limits, full depots, profile replacement and Game Dev isolation.
- 43 Market regression assertions passed, including accounting, demand, imports and Game Dev isolation. The old construction-location assertion now uses the relocated construction site's actual rectangle.
- 157 v143 town/combat, 8 party/replay and 21 education regression assertions passed.
- Existing collision/retained-terrain performance regression suite passed.
- Native desktop and 896×414 landscape visual captures reviewed for Adventures, furnace state, metal cards and Market. Header exits remain in bounds; report downloads are on Reports.
- Archive CRC, complete extraction, prior-file retention and unchanged official hero/art/server files checked. Fresh extracted project imported and launched.

Benchmarked only the cold-tile operation: 345,060 → 3,264 polygon tests, with identical results. No claim of a comparable increase in total FPS. Headless/local-channel tests do not replace real internet multiplayer or exported Web/Windows testing on school hardware.
