# v43 — Ebonwake Citadel and Veyra Spellthief

## Sunpetal: Kindle Bloom

Secondary now lobs a seed to the aimed location, with an arc and landing marker. After landing, a sprout grows for **3 seconds** before blooming. The flower lasts 8 seconds, heals the caster and nearby allies for 3 HP each second within 140 units, and fires an 8-damage fireball at a visible enemy every 1.2 seconds. Range is 330; cooldown is 12 seconds. Each hero can maintain two plants. In PvP, opponents receive no healing. Healing counts toward ability-healing statistics. Sunpetal's primary, Solarbeam and passive remain.

## Astral Rift: more expert pressure

Three Gravity Husks and three Singularity Oracles join the existing enemies. A Husk is a slow melee enemy with a translucent 245-unit slowing aura; standing inside it reduces movement speed to 55%. Leaving it ends the slow quickly. An Oracle holds firing distance and casts a black hole at the player's position: one second of warning, two seconds of collision-aware pulling, then ten radial energy balls. Walls block the pull; invulnerability prevents it. Rift boss health increases from 1,000 to 1,350.

## Hero 27: Veyra Spellthief

A free humanoid mage from Ebonwake, with 105 HP and 245 movement speed, original sprites, and a distinct spell-stealing playstyle.

- **Echo Brand (primary):** a projectile deals 40% of 18 damage on impact, then 60% after 1.2 seconds. Target displacement adds up to 14 echo damage. Repeated hits strengthen the existing mark without postponing its detonation. Cooldown 0.8 seconds.
- **Spell Snare (secondary, level 3):** place a 100-radius snare up to 240 units away. It catches up to six moving hostile shots over 2.5 seconds, then returns a visible fan of 14-damage bolts toward a nearby enemy. Cooldown 9 seconds. It does not catch lobbed explosions or floor attacks, or teammates' shots.
- **Quick Study (passive, level 5):** returned snare bolts slow their targets for one second.
- **Soul Ledger (special, level 6):** link up to four nearby enemies for five seconds, dealing 10 initial damage each. A hit on one shares 25% of its damage to the others, capped at 12 per shared hit. Shared hits cannot create recursive chains. Cooldown 20 seconds. Marks and connecting tethers show linked targets.

## Expert realm: Ebonwake Citadel

A 9,000 × 6,600 ruined citadel over a black sea. Narrow bridges connect the entry hall, Unquiet Infirmary, Brood Reliquaries, Chrysalis Forge and Last Court. Stained glass, damaged masonry, abandoned beds, nest roots, forge embers, stone columns and ceremonial floor inlays distinguish the districts. Columns and floor edges have collision; floor decorations remain traversable.

Twenty-six authored patrol enemies combine these threats:

- **Ashen Revenant:** the first lethal hit leaves a fallen, 25-HP body with a visible three-second finishing window. Finish it to prevent revival; otherwise it returns once at 65% health. No early kill reward is granted for knocking it down.
- **Mercy Cantor:** stays at range, fires green bolts and heals nearby living allies by 30 HP every 2.5 seconds (18 for the final boss). Cannot heal itself or fallen revenants.
- **Brood Reliquary:** stationary nests fire paired shots and spawn Cinderlings, capped at three living children per nest and 75 total enemies.
- **Chrysalis Knight:** a visible six-second charge transforms it into a faster Exalted Wraith with a three-bolt fan. Stun pauses charging; killing it prevents transformation. Remaining health percentage is preserved.
- **Gravity Husk and Singularity Oracle:** create overlapping slow and pull hazards that punish careless approaches.
- **The Last Creditor:** appears after all original patrols are defeated. It circles the player and alternates three marked blasts, a five-shot fan, and singularity bursts. Below half health it moves faster and summons revenants, capped at two living adds. Defeat it and use the exit portal; co-op completes when it dies.

Designed for expert play and coordinated target priority: remove Cantors and nests, finish revenants, then handle the remaining control enemies. Solo remains possible. Enemy health scales with the co-op party. Ebonwake appears near the end of the realm list, before Shattered Oath.

## Students and deployment

Four reusable styles and enemy-controller examples are documented in ABILITY_CATALOG.md and STUDENT_GUIDE.md. New content definitions are JSON; hero and enemy sprites are original project assets, with editable generation source in tools/create_v43_art.py. Existing content, including the v42 forest quest expedition, remains included.

Validation: Godot 4.5.1 compile/import, actual rendered realm and bloom checks, hero damage/construct timing, ally-only healing, hostile-only projectile capture, revival rewards, slow/pull warnings, transformation health, healing, nest caps, connected collision/navigation, final-boss patterns, four clear co-op starts and serialized multiplayer state. Quest, Polarity, Moonburrow, Borough, Gate Defence and summoner regression checks pass. Physical phone and live multi-browser play still need testing after Web export.

Open project.godot and export a fresh Web build for itch.io. No Render service change is required. All players should use the same build.
