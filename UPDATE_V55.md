# v55 — Solar Beam, Dawn Circle and Fern Double
Sunpetal’s Solarbeam now deals 120 base damage. Existing charge time, beam dimensions and cooldown remain.

Mara’s Dawn Circle now shows its full 115-unit area with a golden boundary, bright radial pulse and sweeping blade trails lasting 0.85 seconds. It still deals 48 damage once, with the same cooldown. The shared combat implementation displays the effect in solo and multiplayer.

Pippa’s Fern Double lures ordinary enemies for 3 seconds, then explodes for 24 damage within 150 units. Nearby enemies and enemies it drew in receive a 3-second slow (55% movement speed), respecting walls. Bosses resist the lure but can be hit by the explosion/slow. It then becomes a yellow pulsing healing zone for 3 seconds. Allies inside receive 8 HP at each one-second tick, up to 24 HP. It never heals enemies. Afterglow still grants speed to healed allies. A recast replaces the owner’s old double/zone; cooldown stays 8 seconds.

All phases are host-authoritative and included in multiplayer snapshots. Existing healing attribution records actual spell healing. Descriptions and student ability catalog updated. All v54 features remain included.

Export a fresh Web build for itch.io. No Render changes.
