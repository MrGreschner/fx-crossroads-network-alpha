# Version 21

- Sunpetal: four low-damage seeds, ally healing and a charged wide Solarbeam.
- Snowdrift: snowballs, a protective slowing aura and a growing explosive snowball with knockback and fragments.
- Backbeat: expanding sound rings, three projectile-clearing pulses and a large two-second stun.
- Polarity: magnetic pins, attraction and a damaging wire between anchors.
- Welder hits add a refreshing 2-damage-per-second, 10-second burn. Frostguard’s Crease Wall slows enemies for three seconds on landing.
- Colored indicators show burn, slow, stun and poison. Shared mechanics run on the multiplayer host.
- The Folded Coast: medium-difficulty paper islands, paired folds that transport players/projectiles, ink poison pools, paper fans and the teleporting Cartographer boss. Listed after Frostglass Expanse and before harder realms.
- Ram Descent and other multiplayer modes show XP progress toward the next level.
- Passive descriptions from Diamond Scout onward no longer repeat the level-five requirement. Earlier descriptions are unchanged.

## Verification
Godot 4.5.1 headless checks v13/v14/v17/v18/v19/v20/v21 pass. New checks cover burn refresh/ticks, seed balance, beam charge, slowing aura, growing snowball damage/knockback/fragments, drum pulses/stun/projectile clearing, magnet limits/wire ticks, Frostguard slow, real welder flame burn, sunflower healing, paper realm placement/folds/boss, passive wording and multiplayer status serialization. Physical phone and school-network playtesting remains needed.

## Upload
Open project.godot and export a fresh Web build; ZIP the exported web files for itch.io. This download is the editable Godot project, not a pre-exported browser ZIP. No Render service update is required.
