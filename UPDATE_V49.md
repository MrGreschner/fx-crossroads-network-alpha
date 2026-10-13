# v49 — Bolt Ironcore and Neon Crucible

All v48 changes are included. The roster now has 33 heroes and 22 regular realms, plus Wayfarer Wilds.

## Bolt Ironcore — free robot hero
- Piston Jab: 30 damage, close forward hit, 100 reach, 0.6s cooldown. An extending mechanical fist makes its reach visible.
- Missile Volley (level 3): four rockets over a short volley; each turns toward a visible foe after leaving its launcher. Direct hit: 14 damage; other foes within 58 units take 6 splash. Flight lasts at most 2.3s, speed 360; walls stop rockets and block splash. 7s cooldown.
- Overclock Reserve (level 5): three successful jabs prime one extra missile for the next volley. Three charge pips show progress. A missed jab grants no charge.
- Iron Tempest (level 6): visibly transform into a giant spinning saw for 6s, including a 0.45s transformation. A 78-unit blade deals 12 contact damage every 0.3s to touching hostile bodies, with walls blocking damage. Movement is 42% of normal; dodge and normal attacks are disabled. No invulnerability or damage reduction is granted.
- Saw form has one active attack, replacing Primary: Shock Stomp. It deals 16 damage in a 170-unit radius, briefly stuns for 0.4s and leaves enemies slowed by 50% for the following 2.5s. Stomp cooldown: 2.6s. The normal secondary and special cannot be used during transformation.
- Transformation cooldown: 24s. The normal primary returns automatically when the form ends. Death clears the form and charges. Unlaunched volley rockets are cancelled when transformation starts; rockets already flying remain.

This is an ambush and close-pressure hero: staying outside his blade is the counter, while slow movement and vulnerability prevent an unstoppable chase.

## Neon Crucible — Hard
A 6400 × 4800 floating machine complex, listed after Crossroads High and before expert realms. Connected rooms and broad bridges link the Arrival Dock, Fabrication Foundry, Signal Archives, Coolant Reactor and Continuum Uplink. Off-route Spare Parts and Repair Garden bays provide maintenance pods: each explorer can recover 30 HP once per pod after clearing its sector. Pod repairs do not count as hero spell healing.

Forty-four authored defenders are distributed throughout the map. Six original silhouettes and tactics:
- Hatch Sentinel: a visible floor hatch rises for 0.75s, then warns and fires a three-shot fan.
- Sweep Drone: keeps distance and sends a staggered sweep of telegraphed beam lanes.
- Magnet Hauler: heavy melee machine; warns before a magnetic harpoon that damages, pulls and slows.
- Repair Wisp: keeps distance, repairs nearby machines for 6 HP each second and attacks with curling energy shards.
- Fork Runner: a physical, collision-aware rush after a visible windup.
- Relay Weaver: creates warned electrical fences that persist briefly, making routes harder to cross.

Clear the foundry defenders to awaken Continuum. Its intelligence survives the first three defeats:
1. Forge Shell: missiles, magnetic tether and delayed impact pulses.
2. Archive Shell: sweeping beams, missiles and limited summoned runners.
3. Reactor Shell: spiralling radial energy, missiles and slowing coolant fields.
4. Crown Shell: fast movement, missiles, beam sweeps, rushing impact and staggered pulse clusters.

Each destroyed chassis leaves a wreck and sends a visible upload signal toward a distant backup; after 2.5s the next body appears there. Each has its own original sprite and increasing health. Only defeat of the fourth body unlocks the accessible uplink exit. The objective banner and arrow track progress; before the first boss, the arrow tracks remaining foundry defenders.

## Student extension points
See ABILITY_CATALOG.md, STUDENT_GUIDE.md and NEON_CRUCIBLE_AUTHORING.md. Robot abilities are shared between solo and multiplayer. The realm is authored through rooms, solid props, spawns, pods and an ordered body list in content/campaigns/neon_crucible.json. Adding another upload using an existing chassis requires data changes rather than another hard-coded progression branch.

## Checks
Godot 4.5.1 tests passed for guided travel/impact, wall-blocked rockets/splash and stomp, finite transformation, speed reduction, repeated contact, changed primary, attack cooldowns, vulnerability, death reset, friendly-fire prevention, owner-only multiplayer state and host refusal of dodge during saw form. Realm checks cover all authored enemy positions, paths to all boss bodies, rising turret/warning timing, actual repairs, ranged retreat, physical runner rushes, each chassis's attacks, all four required defeats and the completion exit. Earlier hero, school co-op and gate-guard checks passed. Rendered game frames were inspected for character information, saw form and all four boss rooms.

Physical phone and live itch.io co-op playtesting remains to be done on the newly exported build. The older school co-op test reports a teardown resource warning after passing; the new v49 test exits cleanly.

## Install
Open this editable project in Godot; export a fresh Web build with the existing export preset. Upload the exported Web ZIP to itch.io. No Render service changes are required. Everyone in a party should load the same build. Use v49 instead of v48; it includes the beaver, teapot and requested roster ordering.
