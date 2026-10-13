# v59 — Forty heroes, mirror survival and Overload

Includes all v58 changes. Existing saves remain compatible.

## Dustdevil: Overload
At passive level 5, a 145-radius poison pulse activates every 6 seconds. Enemies hit take 3 poison damage per second for 4 seconds. It affects enemies and PvP opponents, not allies. Replaces Deep Filter and its captured-projectile bonus.

## Caelum Mirrorwright
Placed immediately after Cairnheart. Facet Spear pierces two targets; Prism Fold draws crossed beams with a warning before damage. Clear Sight adds slow.
Twin Self creates an attacking body for 6 seconds, with 60% of current health capped at 66. It fires 15-damage spears. If the controlled body falls, control transfers to the surviving copy with its remaining health. Losing only the copy leaves the original alive; defeating both defeats the hero. Cooldown: 22 seconds.

## Wanderlight — hero 40
A stag guardian from the Wayfarer Wilds quest world. Lantern Comet records shot origins; Compass Turn briefly pauses flying lanterns and redirects them along a new aim. Walking Chronicle replays the latest four primary shots from their original positions and directions at 65% damage, with spectral afterimages. Wall checks still apply. Trailkeeper grants a short movement boost after Compass Turn. No additional realm in this version.

## Installation and checks
Export a fresh Web build for itch.io. No Render changes required.
Automated checks cover poison timing, duplicate damage and survival, both-body defeat, multiplayer snapshots, PvP, piercing, beam warnings, redirection and replay. School, training/quest and existing combat regressions are checked too.
