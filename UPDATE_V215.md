# Crossroads: Realms Beyond — V215

## Hero combat and artwork
- Crosswind Striker has a neutral primary pose without the right-flying ball. His moving primary is a small panelled soccer ball, including immediate multiplayer prediction.
- Snowdrift's primary uses an irregular packed snowball with shaded snow clumps.
- Dribble's little basketball teammate, Patch's Bit Buddies and Merrymask's two distinct wooden understudies have new transparent idle, two movement and attack frames. Summon movement/attacking selects the corresponding animation. Sprites are cached and retain normal hitboxes.
- Fairway Ranger's Chip Shot uses a dimpled golf ball, golf-ball fragments and a turf/dust landing effect. Damage, timing and radius stay the same.
- Mara and Aurel's movement B bodies were respectively 11 and 13 pixels above their idle anchors. Their body positions and compatibility walking aliases are aligned. Quill's old surge/pause movement has been replaced with steady walking.
- Alderjaw's incisors follow his body, and a short active bite checks damage from his current position, once per foe. His tail paddle and falling tree also have new details. Walls still block the attack. Kage's two cuts continue checking the current hero position, with their visible sweep tightened to the same cone.
- Crumb Cook's chop has an attached active hit window. Wick's fright visual follows him and its initial short hit window follows his current position; it does not grant repeated stuns.
- Nera's special now draws a detailed turquoise tram with windows, trim and headlights. Velvet's threaded projectiles and court seal are refreshed. Dustdevil's secondary now draws a bristled brush sweep attached to its owner.
- Caelum's skin is a warmer, muted tan; visor, copper braid, uniform and hand mirror stay intact.

## Ability changes
**Sunpetal:** Solar Finale can turn during its existing 2.5-second charge, at up to 60 degrees per second. Movement is 65% of normal while charging. Inward sunlight rays and a charge ring communicate progress. Damage remains 120; stun still interrupts charging.

**Dustdevil:** Grand Draw can be aimed while channeling, turning up to 2.8 radians per second. Existing cone, pull, duration and wall rules remain.

**Patch — Reset Pulse:** radius increases from 135 to 300. The expanding wave still deals 18 damage and clears hostile projectiles. Each ally it reaches loses negative temporary effects; each enemy loses positive temporary effects, including legacy player shields/haste/invulnerability/stealth and active chill protection. Friendly summons are included. Range and line of sight apply. Each target is purged once per cast; this does not grant continuing debuff immunity or remove intrinsic equipment/passive effects.

**Patch — Combo Buffer:** replaces the special-duration passive. Every fourth primary cast adds a seeking Confirm bolt using the primary's damage (14 base), and grants 15% movement speed for two seconds. Available with the normal level-five passive unlock; no special is needed. Bit Buddies retain the normal nine-second duration before mastery changes.

## Title, loading and intro
A new matte pixel-art town background sits behind the main menu. Loading miners, guards and Bramble use new small animated sheets, and the portal has softer stone colours and carved details. The intro cat is below the encounter beside the fish. Both sun and moon appear; time-of-day lighting and the active celestial body still change with Edmonton day/night. Loading timing and accessibility/reduced-motion behaviour are preserved. The menu gallery also uses the new Bramble art.

## Validation and playtest limits
3,719 automated checks passed: 3,590 existing hero/frame/stat/UI/cave checks, 113 focused combat/animation checks and 16 networking regressions. Checks cover steering rates, release/stun behaviour, moving hit locations, repeat-hit prevention, walls, pulse team/range/status rules, summon frames and caching, passive unlock/cadence, JSON state and predicted projectile appearance. Seven browser scripts pass Node syntax checks; all referenced local HTML resources exist. A dedicated authority starts on protocol 11. Native Godot/OpenGL visual checks cover companion frames, hero alignments, effects, the menu and intro. Existing test-fixture resource-in-use warnings remain at shutdown. Browser gameplay and real-device multiplayer/performance playtesting remain; this is not a claim of an eight-client live playtest.

## Deployment
1. Deploy **Crossroads_v215_Server_Update.zip** to Render first.
2. Upload **Crossroads_v215_Web.zip** to itch.io.
3. Retain **Crossroads_v215_Editable.zip** for editing and debug playtests.

No live deployment was performed. Preserve existing accounts, database, keys, environment variables, saves and records. No database migration or record reset is required. Backend account/teacher/database behaviour is unchanged; server authority receives the matching combat, content and rendering source. Protocol remains 11.
