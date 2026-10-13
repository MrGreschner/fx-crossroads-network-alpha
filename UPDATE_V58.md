# v58 — Silk, fragments and school doorway repairs

- Diamond Scout's Triple Play projectiles stun enemies hit for 2.5 seconds. The stun uses shared combat state in solo, co-op, Descent, defence and PvP.
- Fairway Ranger's Course Ricochet now hits up to five different targets, keeping its existing 20% damage falloff at each jump.
- Chip Shot retains its travelling lob and 24-damage, 80-radius initial explosion. On impact, six visible fragment bombs scatter outward, land with radius 32 and deal 4 damage each. Children cannot split again. Existing cooldown stays 4 seconds.
- School connected rooms now share continuous walkable ground. Padding applies to exterior walls rather than leaving gaps at touching room boundaries. This fixes the elementary playground's invisible seam after its gate unlocks and covers the other schools too. Doors still require their proper objectives, and navigation refreshes when they open.

## Hero 38: Velvetwing
A lavender moth scholar with gently floating, fluttering movement. Her visual flight keeps ordinary ground collision and movement speed; she cannot fly through walls.

- **Threaded Needles:** two 12-damage shots start at opposite wings and converge ahead before spreading apart. 0.75-second cooldown.
- **Silk Tripline:** three silk traps arm after 0.6 seconds and last four seconds. Crossing a line snaps it for 22 damage and two seconds of slow. Each enemy can trigger only once per cast. Six-second cooldown.
- **Lunar Loom:** two luminous wing ribbons sweep outward for 2.4 seconds. Contact deals 18 damage, capped at three hits per enemy; walls block damage. Fifteen-second cooldown.
- **Soft Landing:** casting Silk Tripline grants 15% damage reduction for two seconds.

105 health, speed 235, free to select. Multiplayer uses host-owned collisions and replicated effects. Flight animation works in town and multiplayer as well as solo.

All v57 features are included: two added quests, training projectiles, moving target, centre dummy and the Veyra/Pippa roster placements.

Open project.godot, test with F5, then export a new Web build and replace the itch.io upload. No Render changes required. Godot combat, co-op and school regression checks pass; actual mobile/browser play should be checked after export.
