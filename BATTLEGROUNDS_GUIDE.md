# Battlegrounds

A match combines playable heroes with automatically marching armies. All 72 heroes are available. The two armies are the **Ram Alliance** and the **Ironhollow Legion**, a coordinated boar faction. Their numbers are equal; their appearance differs.

## Start a match

Enter the glowing battlefield clearing **north of town’s front gate**, choose Battlegrounds in **Gather Your Party**, or use the Adventures menu. Choose the map and **3v3 / 4v4 before hosting**. Join by room code or public-room listing. Tap/drag into a team area. Start requires exactly six or eight human players in equal teams. Battlegrounds has no practice bots or spectator seat; the Arena keeps those features.

Three players per side use three paths. Four use four. Each hero owns a barracks on its side. There is an allied heart behind those barracks. Destroy **all opposing barracks**, then the unshielded heart, to win. Heroes respawn after seven seconds at their personal barracks location, including if its building was destroyed. A destroyed barracks stops producing and cannot be upgraded.

## Your economy

Start with 100 gold. Receive 6 gold every three seconds. An army kill gives its owner a bounty (12–26 gold, according to the target’s role) and 8 hero XP. A hero kill made by a hero gives 45 gold / 30 XP. Destroying an opposing barracks grants each teammate 100 gold / 60 XP. Army damage is separate from hero damage mastery; direct hero damage counts toward mastery. Battlegrounds does not award Gladiator streaks or trophies.

Your barracks starts with **two foot soldiers every 18 seconds**. Stand near your own barracks and press **E / Interact** to open its recruiting/upgrade panel. Each recruit purchase adds one soldier of that type to subsequent waves; it is not an immediate one-time summon. Types can coexist. Active troops are capped at **24 per owner**: 144 total in 3v3, 192 in 4v4. When existing troops fall, reinforcements can spawn again.

| Role | Alliance appearance | Ironhollow appearance | Purpose |
| --- | --- | --- | --- |
| Foot soldier | Ram guard with sword | Boar grunt with blade | Basic melee frontline |
| Archer | Ram archer | Boar bowman | Ranged pressure; backs away when crowded |
| Healer | Rabbit with healing staff | Boar field cleric | Heals nearby allied troops or heroes |
| Catapult | Alliance siege cart | Legion siege cart | Slow, long-range splash projectile |
| Mage | Ram spellcaster | Boar hex caster | Ranged splash pressure |
| Berserker | Larger ram fighter | Larger boar raider | Faster melee attacker |
| Tank | Armoured ram shield bearer | Armoured boar bulwark | High health, slow frontline |
| Long-range scout | Ram longbow | Boar sharpshooter | Fragile, longest-ranged pressure |

Army upgrades affect **future troops**: melee/ranged damage +12% per rank, healing +15%, vitality +12% health. Production removes 1.5 seconds per rank from the 18-second march interval. Each upgrade caps at four ranks. Basic foot soldiers cap at six per wave; other roles cap at three per wave. Upgrade prices rise with rank; the UI shows the exact price.

## The contested market

There is **one hero item shop**, in the centre. Stand near it and press E / Interact, choose an item, then Buy Item. You still have three item slots. The host checks distance, gold, and whether you are alive. The battle continues while a shop is open.

Coordinate: one player can build a frontline, another healers, and another ranged/siege pressure. Hero mobility and crowd control let players rotate between paths or secure the market.

## Maps

- **Verdant Front:** woodland march roads, tree islands, ponds, lateral routes and a central market. The simpler map for learning the mode.
- **Iron Rain:** a war-zone interpretation within Crossroads, with bunkers, sandbags, craters and flyovers. Staggered airstrikes show orange warning circles before impact. Bombs damage both heroes and both armies. Leave the circles before impact; artillery projectiles also travel before exploding.

## Student extension points

The isolated module is `scripts/battlegrounds.gd`. It owns troop roles, prices, lane placement, upgrades, bounded troop AI, map drawing, snapshots and host validation. `scripts/arcade.gd` integrates the lobby, player combat, respawning, item store and packets. Army actors use distinct keys, so the ordinary hero combat/status system can target them without treating them as enemy realm encounters. Summons can fight troops, necromancers can use fallen soldiers, and Change of Heart can temporarily convert a soldier for eight seconds.

To add a troop role, update the role/stat/name arrays, its drawing/AI role, recruiting limits and tests together. To add a map, add its ID to the map list **and** the room-service allowlist; provide obstacle, scenery and hazard logic. The host is the game authority; the Render service handles rooms/signalling, not army simulation. Protocol 26 isolates v92 multiplayer from older builds.

Reference consulted: the creator’s description of [Footmen vs Grunts Elite](https://www.hiveworkshop.com/threads/footmen-vs-grunts-elite.298097/). FX Crossroads uses its own code, characters and visuals.
