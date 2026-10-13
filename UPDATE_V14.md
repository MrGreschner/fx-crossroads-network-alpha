# v14 — Dawnblade, Stormscribe and Clockwork Orchard

Includes v13's phone layout and Silverfall Reach, and v12 public matchmaking. No Render update is needed. Export this project as Web and replace the itch.io game ZIP. All players should refresh to this build.

## New free heroes
**Mara, the Dawnblade** — sword melee specialist. 130 HP; speed 225. Sword Cut deals 28 damage at 82 reach with a 0.6-second cooldown. Forward Lunge travels 160 units, deals 34 damage, and recharges in four seconds. Dawn Circle deals 48 damage within 115 units with a ten-second cooldown. Resolute uses the existing 10% guard passive at level five. All melee visuals stay close to her sprite.

**Orin, the Stormscribe** — a fragile wizard. 90 HP; speed 220. Spark Script fires a 19-damage projectile, 410 reach, 0.7-second cooldown. Threefold Lightning fires up to three simultaneous bolts from the wizard to separate targets in front of him: 22 damage each, 350 reach, 4.8-second cooldown. It cannot hit one enemy three times; obstacles block targeting. Fewer enemies means fewer bolts. The same rules apply in multiplayer; PvP excludes teammates and defeated players. Stormward reduces incoming damage by 60% for two seconds with a 13-second cooldown. Spell Rhythm uses the existing 20% quicker primary passive at level five.

Secondary and special retain the standard level-three and level-six unlocks. Both heroes are available in Character Hall and every multiplayer mode.

## The Clockwork Orchard
A 7,200 × 4,200 realm with brass paths, clock arches, mechanical orchard trees, and 44 original enemies. Pendulum Moths shoot at range; Tick Acorns chase on mechanical legs. Their silhouettes and sprites are distinct.

The Hourglass Hart is an antlered mechanical guardian with 900 base HP. It alternates a ring of five delayed clock strikes, an aimed pendulum line, and a targeted hourglass impact. Every attack is shown before damage lands. It appears after the solo realm's enemies are cleared, or in co-op stage three. Co-op adds 55% boss HP per additional player.

## Hero names
Internal character IDs and sprites remain unchanged, preserving saved selections and student data references. Display names now read:
- Young Ram (unchanged)
- The Rebound Knight (basketball)
- The Lorekeeper (book)
- The Velvet Prowler (cat)
- The Frostguard (goalie)
- The Blightmender (medic)
- The Starfarer (navigator)
- The Diamond Scout (baseball)
- The Fairway Ranger (golfer)
- The Crosswind Striker (soccer)
- The Emberwright (welder)
- Reed, the Ferryman
- Mara, the Dawnblade
- Orin, the Stormscribe

## Editing and checks
New data is in content/characters/dawnblade.json, content/characters/stormscribe.json, content/regions/clockwork_orchard.json, and its three content/enemies files. The editable realm scene is scenes/realms/clockwork_orchard.tscn. Original art generation is tools/build_clockwork.py. The wizard uses the shared chain attack style with `fork: true`; this opts into simultaneous targeting without changing the basketball's bouncing chain attack. scripts/lightning.gd supplies the shared lightning visual.

Headless Godot checks cover the new registry entries, naming, 44 enemies, three separate equal-damage lightning hits in solo/co-op, caster-origin bolts, sword reach, wizard shielding, and all three guardian patterns. Existing v13 phone/Silverfall tests and room-service tests also pass. Physical phone and live multiplayer playtesting remain useful after export.

Run `godot --headless --path . --script tests/v14_heroes_clockwork.gd` and `godot --headless --path . --script tests/v13_mobile_silverfall.gd`.
