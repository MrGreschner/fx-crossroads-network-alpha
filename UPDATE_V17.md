# v17 — Vesper and Astral Rift

Includes every v16 feature. The larger graphics overhaul is deferred; this expansion uses the current original pixel-art style. Export a new Web build and replace the itch.io ZIP. No Render update is needed. All players should refresh to this version.

## Names
Removed the remaining repeated article: Diamond Scout, Fairway Ranger, Crosswind Striker and Emberwright. Their IDs, stats and abilities are unchanged. Generation scripts preserve these names too.

## Vesper
A free bat star-courier: 100 HP, speed 245. Available in town and all multiplayer modes.
- Orbitblade: a returning disc, 16 damage per pass, 220 outward reach, speed 380, 1.1-second cooldown. Each enemy can be hit once outward and once returning; it returns toward the owner's current position. Geometry blocks travel. It expires after three seconds; a maximum of four discs per owner prevents accumulation. PvP respects teams and excludes the owner.
- Comet Seal: targeted 32-damage blast, 85 radius, 300 reach, five-second cooldown.
- Starlit Veil: 60% damage reduction for two seconds, 12-second cooldown.
- Night Rhythm: secondary cooldown is 20% shorter from level five.

Orbitblade is a new shared attack style (`return_disc`) implemented in realm_trials.gd. The host owns damage in multiplayer; serializable snapshots carry disc visuals to guests. Other abilities retain standard unlocks and shared combat behavior.

## Astral Rift
An 8,000 × 3,200 shattered observatory with a starfield floor, floating upper observatory platforms, glowing astrolabes, star obelisks and three timed beam crossings. Floor and bridge footprints define safe walking space; void is impassable. Red WAIT / green CROSS markers identify the gate timing (1.5 seconds active in a 5.5-second cycle). The stars and constellation lines shimmer while playing.

45 unique enemies:
- Rift Weavers: paired violet portal strikes around the player's position, with one second of warning.
- Prism Kites: a rotating cyan beam with a 1.15-second warning.
- Comet Urchins: warning-marked charge lines; the enemy moves to the charge destination on impact.

Their custom attacks use shared authority and warning logic in solo/co-op, alongside normal close-contact damage. Enemies are isolated from generic arena/defense/Descent pools.

The Eclipse Engine appears after the solo enemies are cleared or in co-op stage three: 1,000 base HP, plus 55% per additional co-op player. It alternates six orbiting impact zones, three parallel eclipse beams, and a targeted collapse that summons one Prism Kite (maximum three live kites). Every attack gives a visible warning before damage.

## Existing fix
The solo gameplay loop now updates the shared adventure controller for all realms, allowing Silverfall, Clockwork and other custom guardians to use their programmed attacks during normal gameplay. Previously only Shattered Oath's controller was updated by that loop.

## Student editing
Data: content/characters/vesper.json, content/regions/astral_rift.json and the four new enemy JSON files. Scene: scenes/realms/astral_rift.tscn. Art generator: tools/build_astral.py. The safe-floor rectangles and timed gates are in realm_trials.gd; adjust them with the scene if moving the bridges or platforms. Warning attack patterns live in that same shared controller.

## Validation
Godot checks cover names, 45 enemies, timed gates, void/bridge collision, one hit on each disc leg, catching and disc caps, ordinary-realm disc updates, all three enemy attack styles through the actual gameplay loop, Eclipse attack patterns, co-op damage parity and boss setup, and JSON snapshot compatibility. Silverfall/mobile and Clockwork/hero regression checks also pass. A live browser/phone playtest is still needed after export.

Run `godot --headless --path . --script tests/v17_astral.gd`.
