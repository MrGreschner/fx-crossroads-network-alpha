# FX Crossroads v120

- Hearth Herald: held Lantern Light cone damages enemies and heals allies/self. 12 base damage/s and 4 HP/s; walls stop it. Releasing, death, stun or leaving combat stops the light.
- Hollow Rider: Spectral Scythe tap/hold (25–45 damage, 1.3s full charge). Full charge adds 2 bleed damage/s for 3s. Broad Reaping retains its wider, lower-damage tradeoff and can charge too.
- Clockwork Apiarist: Amber Needle tap/hold (18–36 damage, 1.4s charge). Full charge stuns for 1.25s. Keeper’s Crook remains its melee alternative.
- Recess Warden: Safety Whistle is now a 110-wide piercing sound wave (18 damage per target, once). Walls stop it; the nearby ally ward remains.
- Harbor Bell: Safe Passage has animated rolling wave crests instead of a circle; protective mechanics unchanged.
- Training Guide/shelter moved left; Hero Book moved right, closer to the dummies.

## Installation
Extract into a fresh folder and open project.godot in Godot 4.5.1. Export Web again and upload the new web export ZIP to itch.io. Export Windows again if updating the downloadable game. This editable ZIP is the source project, not the playable web export. No Render server files/settings changed.

## Verification
Godot headless import and v120 combat tests passed. Tests cover tap/full charge, bleed, stun on projectile impact, repeated held light, enemy-vs-ally handling, remote release/watchdog, and piercing echo. v117 charge/network and v118 tutorial-death regressions passed. Training layout and the three new light/wave effects were rendered and inspected. Browser/device live multiplayer should still be checked after export.
