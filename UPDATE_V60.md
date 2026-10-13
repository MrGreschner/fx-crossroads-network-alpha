# v60 — Identical mirrors and elemental lanterns

Includes all v59 content; still 40 heroes. No new realm or server changes.

## Portraits and Caelum
Velvetwing, Caelum Mirrorwright and Wanderlight now have idle sprites, restoring Character Hall portraits and standing poses in multiplayer. The main sprite loader also falls back to the numbered idle frame for student sprite sets.
Caelum is a mirror craftswoman with a copper cloak, long dark braid and a hand mirror rather than a diamond staff.
Twin Self lasts 6 seconds. The duplicate copies actual movement deltas, stops when the player stops, uses the same animation timing and aim, and copies both primary and secondary attacks at 60% damage. It no longer chases targets or fires independently. Collisions and its own stun/slow still apply. It has the same sprite, name/title, health-bar style and minimap marker as its owner; no transparent copy tint or identifying countdown ring.
Survival rules remain: the copy starts with 60% of current health (max 66); if the original falls first, control transfers to the surviving body with its remaining health. Defeating both still defeats the player.

## Wanderlight
Lantern Comet now travels 1200 units at speed 300: about 4 seconds of flight before walls or targets stop it.
Starts in Earth mode. Compass Turn briefly pauses and redirects the caster's flying lanterns, infusing them with the current element. With none in flight it launches a 16-damage infused guide light. The direct projectile damage remains, with the following impact effects in an 85-radius area:

| Element | Splash | Status | Lingering terrain |
| --- | --- | --- | --- |
| Earth | 12 damage | Poison: 2 damage/second for 4 seconds | Seeds grow roots after 2 seconds; roots slow enemies by 45% for 8 seconds after growth. |
| Fire | 20 damage | Burn: 3 damage/second for 4 seconds | Lava remains for 8 seconds, renewing burn on enemies entering or staying inside. |

Roots briefly retain slow after enemies leave (1.2 seconds). Burning lasts up to 4 seconds after leaving lava. These status effects do not stack into multiple copies of the same damage-over-time effect. Terrain effects are limited to six patches per owner. Allies and the caster are unaffected; PvP rivals can be hit.
Walking Chronicle still replays the last four primary shots at 65% damage from their original positions. Only after the final replay does it switch Earth to Fire or Fire to Earth. Already-infused projectiles retain their original element. The current element is shown on screen and infused bolts have matching seed/flame effects.

## Student notes and validation
ABILITY_CATALOG.md and STUDENT_GUIDE.md describe movement-copy illusions, delayed roots, lingering lava and post-replay element switches.
Checks cover portraits, movement/attack copying, collision, elemental impacts, poison/burn values, delayed roots, terrain expiry, friendly targeting, PvP targeting and network state. v59 survival, v58 school/combat and multiplayer regression checks passed. Portraits and effects were also visually inspected in Godot.

Export a new Web build and upload it to itch.io. No Render changes required.
