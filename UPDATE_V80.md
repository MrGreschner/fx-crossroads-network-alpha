# v80 — North Gate outposts and fixed entrances

- Every wave uses the same entrance at the far end of its lane, including elites, Sable Voss respawns and the wave-30 Tollbreaker.
- Enemies follow the roads and must destroy the lane outpost barricade before advancing toward town. Chasing, strafing and rival dodges cannot bypass an intact checkpoint.
- Each outpost has visible health, scaled for party size. Destruction leaves rubble, changes its minimap marker and stops its extra soldier reinforcements. The main base continues sending guards.
- Outpost health and destruction synchronize to guests through the existing state snapshot, including late joins and recovery. Fresh matches restore all outposts.
- Allied lane guards move at 165 instead of 205 (about 20% slower). Hero summons and player movement are unchanged.

## Validation
Godot 4.5.1 clean import; automated checks for wave/rival entrance positions, outpost damage/destruction, co-op snapshot state, reinforcements, and actual enemy movement along all three roads. Native rendered intact/destroyed outpost checked. School-device multiplayer remains a deployment check.

## Install
Extract this full editable project into a fresh folder and open project.godot. Export a fresh Web build for itch.io. Room service remains v14; this patch requires no additional Render changes beyond the previously planned v14 update. All players should use the same game build.
