# FX Crossroads — World overhaul v6

Open project.godot and press F5. Use a fresh extracted folder.

## Larger worlds

- Gate Defence: 16,000 × 11,500 world, with long north, west and east roads converging on the town gate. Up to four players; solo remains available. A nearer first vanguard starts the action before later enemies march from the distant road ends.
- PvP: 6,200 × 4,200 wooded battlefield with a central courtyard, flanking roads and cover. Two to four players, including 2v2.
- Ram Descent: 6,000 × 3,600 cave floors.
- Co-op: uses the selected realm’s full scene, terrain, roads, scenery, obstacles and enemy placements. Two players.
- Lobby controls disappear during a match. The camera follows your hero, with a compact HUD and minimap. Escape opens the return-to-town panel; Enter returns, Escape resumes.

## Gate Defence buildings

Walk up to a building and press E. Combat continues while you shop. Press E or Escape to close.

| Building | Keys | Upgrades |
|---|---|---|
| Barracks | 1 / 2 | Guard health / additional soldiers |
| Forge | 1 / 2 | Guard damage / armour |
| Archery | 1 | Re-equip ram soldiers as ram archers; further upgrades improve archers |
| Sanctum | 1 | Area attack guards |
| Supplies | Item selector and Buy button | Carry up to three items |

The shared guard army has ram soldier sprites with horns, helmets and shields. Ram archers carry bows. The town gate also has ram soldiers. Guards patrol outward on all three approaches; surviving guards benefit from health and damage upgrades immediately.

## Heroes and movement

Hero health, movement speed, attack reach, attack arcs, cooldowns and ability styles read the same character JSON used by normal realms. Melee effects are directional and centred at the hero, with no oversized offset circle. Charges move the hero through the world. Beams, chains, summons, stealth, blocks and healing have distinct behaviour. Attack effects and damage numbers are sent to guests.

Shift dodge travels over a short eased movement with an afterimage trail, rather than teleporting. Your selected hero is retained after death and when returning from multiplayer, and is saved with the local profile.

## Training yard

The Training Yard entrance is on the southeast side of town. Press E at the entrance. Your selected character has all attacks unlocked; four stationary targets show damage and reset when depleted. Practice gives no gold or XP. Press E at the return portal to leave.

## Realm order

Whispering Grove → Ember Quarry → Sunfield Expanse → Frostbound Rink → Orbital Breach → Hollow Quarantine.

## Student editing

The new world layouts are editable Godot scenes under scenes/realms/: defense_world.tscn, arena_world.tscn, descent_world.tscn and practice.tscn. Edit GroundPaint polygons, Obstacles markers and Buildings markers. The existing character, enemy and realm content workflows remain available.

## Validation

Godot 4.5.1 headless import and script compilation passed. Automated smoke checks exercised town/practice entry, every hero’s attacks in every mode, training target reset, character retention after death, map loading, guard spawning and archer upgrades, respawn, and host/guest state decoding. Real multi-computer connectivity and visual gameplay balance still need a playtest.
