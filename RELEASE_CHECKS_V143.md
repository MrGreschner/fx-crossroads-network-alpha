# v143 release checks

- 157 town/combat assertions: Academy gates, direct-entry protection, unlocked classroom, doorway collisions, all road segments with upgrades built, new realm actor counts and accessible placement, AI movement/casts, bounded effects, snapshots, intermediate boss progression and actual healing amounts.
- 8 party assertions: co-op additions, guest warning snapshots, healing feedback, host-only replay, five-second countdown and retained room/roster.
- Six regression suites from v139–v142 passed (141 assertions): education evidence, marking, modes, examples, lobby and custom learning paths.
- Native visual capture reviewed central, western, southern and eastern town areas, upgraded layout, Quarantine Warden and green healing feedback.
- Editable archive CRC, complete extraction and prior-file retention checked. Official hero data/artwork and room-service source verified unchanged from v142.
- Fresh extracted project imported and launched with Godot 4.5.1.

Network tests use local fake open channels to exercise host/guest state; they are not a live two-computer internet test. Graphics capture uses native compatibility rendering. Web export, school Chrome context recovery and Windows export must be spot checked after export on the target devices.
