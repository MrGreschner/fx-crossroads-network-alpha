# v127 — Crossroads Studio: clearer choices, more creative control

## Included

- Fixed the vertically squeezed empty animation message. Charge-up and attack animation editors each support eight portable pixel frames.
- Ability Lab now uses Build, Shape, Power and Effects tabs. Attack families filter available behaviours and expose relevant settings.
- Nine melee visual choices plus custom frames; reach and 20–360° arcs. Fourteen projectile graphic presets plus custom frames; straight, lobbed, homing, returning and waving paths; direction/cursor destinations; aim guides; range, speed, count and spread.
- Charge toggles and six visual choices, with custom charge frames. Damage, ally healing, life steal, statuses and cooldown controls.
- Dedicated control/support and summoning options: ground fields, mines, protection, pulling, buffs; six minion looks plus custom images; melee, ranged and healing minions with tunable health, pace and lifetime.
- Interactive live preview: move, aim and attack while the code remains visible. Automatic replay remains available.
- Built-in and saved Custom ability selection areas are explicitly separated in Hero Workshop.
- 20 new working passives, for 37 total. Settings use the same bounded runtime in Lab, Workshop tests and solo custom-hero gameplay.
- Studio has a three-second skippable animated welcome; the town building sits on a terrace east of Training Yard with a wider, readable sign and connecting walkway.
- Classroom desks have books, grain, legs and chairs, with a clear centre aisle and approach to the assignment board. The teacher's name only appears beside his in-world character.

## Deployment

1. Extract this editable ZIP into a fresh folder; open `FX_Crossroads/project.godot` in Godot 4.5.1.
2. Run the game and try Studio → Ability Lab → Interactive test. Check a saved Custom ability in Hero Workshop and Training Yard.
3. Export a fresh Web build using your existing preset. Zip the exported Web files with `index.html` at the ZIP root and replace the browser-playable upload on itch.io. This source ZIP is not the Web export.
4. Re-export the Windows build if distributing the downloadable version.
5. **No Render changes or room-service redeploy are required.** This update does not change the backend.

Official hero content and assets are retained. Custom heroes remain solo/training only. The ability language is bounded Crossroads Script, not unrestricted code execution. v1/v2 workshop projects remain readable; new projects use schema 3.

## Validation

254 automated checks passed across Studio, animation, UI, profile transfers and the new attack-family/motion/charge/passive tests. Godot parse checks passed. Rendered interface reviews and archive extraction checks accompany this release. Actual phone/browser GPU performance has not been tested in this environment.
