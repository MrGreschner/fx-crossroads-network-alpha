# v67 — Faster effects and clearer hero abilities

Includes all v66 profile, mastery and town features. Export a fresh Web build and upload it to itch.io. No Render changes are needed.

## Performance
- Kage Moonstep’s Windwheel filters nearby collision candidates before obstacle-path checks, avoids repeated distant-enemy lookups, and bounds catch-up work after a stalled frame. Outward/return damage is unchanged.
- Sunfield uses four cached animated grass textures with viewport culling instead of generating individual blade polygons every frame. Concealment and the transparent gap around players remain.

## Thistlebond
- Fixed solo Change of Heart: the normal Special action now selects and validates its target before spending cooldown. Non-boss conversion lasts eight seconds, with defeat rewards awarded once.
- Binding Thorns: marking at least two living enemies poisons each for five seconds at 2 damage per second. A lone mark does not trigger poison; existing poison runs its full duration.

## Velvetwing
- Silk Tripline’s passive grants 15% damage reduction for 2.5 seconds with a faint protective orb. Melee attackers receive poison for three seconds: 2 damage every half second.
- Lunar Loom travels outward, joins for one second of small-area damage, then splits and returns to Velvetwing. Each moving leg can hit an enemy once; the central pause ticks damage four times. Maximum damage to one target is 60 before other modifiers.

## Cloudloom
- Stormcatcher replaces the small passive heal. Tailwind Seam catches up to three hostile moving projectiles and fires a seeking lightning spark for 10 damage per catch. The active seam has a visible electrical effect. Floor hazards and lobbed area attacks are not caught.

## Validation
Targeted v67 combat checks passed, along with conversion, hero/school, co-op, mastery and profile restoration regressions. Grass and ability effects were inspected in a rendered Godot preview. Phone performance still depends on device/browser; this build has not been tested on a physical phone.
