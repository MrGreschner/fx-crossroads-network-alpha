> **Student creation tools (v124):** Crossroads Studio has its own bounded, reusable attack library and live code editor. See [CROSSROADS_STUDIO_GUIDE.md](CROSSROADS_STUDIO_GUIDE.md). Official bespoke moves below retain their existing behaviour.

> In-game student authoring: see [HERO_WORKSHOP_GUIDE.md](HERO_WORKSHOP_GUIDE.md) for the current workshop subset, portable projects, and tests. This larger catalog also includes bespoke main-game abilities that are not yet workshop modules.

# FX Crossroads — Ability Design Catalogue

A student reference for designing a complete, playable hero. This is a catalogue of the **current choices**, not a history of updates. Start with the checklist, choose a play style, then copy a working example before changing it.

## Find what you need

1. [What you need to make](#1-what-you-need-to-make)
2. [How abilities and numbers work](#2-how-abilities-and-numbers-work)
3. [Attack types you can choose](#3-attack-types-you-can-choose)
4. [Buffs, debuffs and control](#4-buffs-debuffs-and-control)
5. [Passive choices](#5-passive-choices)
6. [Mastery and alternate abilities](#6-mastery-and-alternate-abilities)
7. [Artwork and animation](#7-artwork-and-animation)
8. [Items, food and enemies](#8-items-food-and-enemies)
9. [Build and test checklist](#9-build-and-test-checklist)

## 1. What you need to make

| Part | What to provide | Where it goes |
| --- | --- | --- |
| Identity | Unique lowercase `id`, display `name`, short lore, sprite prefix | `content/characters/<id>.json` |
| Base stats | `max_health`, `speed`, `run_cost` | Same hero file |
| Primary | Name, implemented style, damage, cooldown and honest description | `primary` object |
| Secondary | A useful different action; unlocked at level 3 | `secondary` object |
| Special | A memorable action with a clear cost, warning or long cooldown; level 6 | `special` object |
| Passive | Description and an implemented `passive_effect`; level 5 | Hero file |
| First mastery technique | Optional change to one ability, including its trade-off | `mastery.technique` |
| Final mastery technique | A complete replacement attack on a **different ability button** | `mastery.final_technique.attack` |
| Mastery title | A title that recognises expertise with this hero | `mastery.title` |
| Character art | Idle, two walking poses and attack pose | `assets/<sprite>_<pose>.png` |
| Ability art | Show aim, travel, warning, impact and status clearly | Existing effect renderer or a new combat module |
| Registration | Add the hero id once, in the desired selection order | `content/manifest.json` → `characters` |
| Hall metadata | Short gameplay summary, one or two lore sentences, concise passive summary, role and difficulty | `content/hero_library.json` → `summary`, `lore`, `passive_brief` |
| Compact card text | Optional brief effect summary; full descriptions open on click | Ability `ui_brief`; otherwise derived from style and damage |

Design the hero’s job first: close fighter, ranged attacker, protector, healer, trap setter, summoner or controller. Give it a weakness. A hero with healing or strong control should give up some damage, reach, mobility or cooldown speed.

**Example to start from:** [Chronicle Keeper](content/characters/chronicle.json) includes all three attacks, a passive, both mastery choices and a title. [Young Ram](content/characters/ram.json) is a simpler close-combat example. Make a copy under a new id; do not overwrite an existing hero.

## 2. How abilities and numbers work

Abilities are JSON objects. `style` chooses an existing mechanic; its display `name` does not create behaviour. Writing a new style or passive name requires implementing it in GDScript.

| Field | Meaning | Important detail |
| --- | --- | --- |
| `name`, `description` | What players read | Explain targeting, duration, risk and total/pulse damage. Keep descriptions accurate. |
| `style` | Exact engine identifier | Copy one from the tables below. Similar names are not interchangeable. |
| `damage` | Base hit or pulse damage | For repeated attacks, add up the pulses/projectiles. Healing and utility skills may use 0. |
| `cooldown` | Seconds between casts | A high-damage/control ability needs a longer recovery. |
| `range` | Travel, cast or targeting distance | Depends on style; not automatically the explosion size. |
| `radius`, `blast_radius` | Area radius | Which field is read depends on the selected style. |
| `speed`, `travel_speed`, `wave_speed` | Movement of a shot/lob/wave | Use the field in that style’s working example. |
| `count`, `jumps`, `jump_range` | Number of shots or linked targets | Limit hits and prevent repeated bouncing on the same enemy. |
| `spread`, `arc_degrees`, `width` | Coverage | `spread` is normally radians; `arc_degrees` is degrees; `width` is world units. |
| `duration`, `charge`, `fuse` | Lifetime or delay | Provide a visual warning during any wind-up. |
| `color` | Effect colour, e.g. `#a6dddd` | Colour is only visual; it does not apply a status. |
| `visual`, `visual_texture` | Supported drawing variant or effect asset | A picture alone does not create hit detection. |

World distances use game units; timers use seconds. A damage-over-time amount means damage **per tick**, not total damage. Consider accuracy, exposure while casting, number of targets and the whole combo when balancing.

**A kit-specific style is not a generic mix-and-match spell.** For example, Rewind Chime needs Second Needle’s marks, Magnet Wire needs pins, and Compass Turn redirects Lantern Comets. Several older bespoke kits keep geometry or timing in code. The “example fields” below are present in working data, but not every field changes every style. Read the linked example and its renderer before editing a new parameter. Adding an arbitrary JSON field does not make it work.

### Press, hold and release controls

Charged abilities release on **button-up**; cooldown starts when the attack is sent. A short tap gives the base attack. Charge strength caps, so holding longer does not grant unlimited damage. Stun, death, opening a menu or changing hero cancels the held cast. Mouse, keyboard and touch buttons use the same rules. In multiplayer the host measures charge duration; a client never supplies its own damage or charge multiplier.

Add `hold_charge` to an implemented ability. Numeric multipliers interpolate from 1 to the configured value over `seconds`. Example:

```json
"hold_charge": {"seconds": 1.1, "damage": 1.85, "speed": 1.7}
```

| Option | Supported use |
| --- | --- |
| `seconds` | Maximum power-up duration; 0 means hold to aim, with no damage boost. |
| `damage`, `speed` | Maximum multipliers for hit damage and projectile speed. |
| `size` | Maximum size multiplier for shared charged projectiles; visual and collision radius grow together. |
| `blast`, `splash` | Explosion/splash radius multipliers; `splash` also raises splash damage up to 1.5×. |
| `distance_charge`, `min_range` | Fairway Ranger: marker moves outward from minimum range to maximum range as charge grows. Mouse/stick controls direction. |
| `knockback`, `stun` | Alderjaw's Tail Slap: multipliers for its 80-unit push and 1.2s stun. These are kit-specific. |

Lobbed abilities with `travel_speed` now show their targeting marker while held and cast on release, even without a power-up configuration. Nullweaver's triangle likewise aims while Space is held and casts on release. Continuous/channel attacks retain their own hold behaviour. A charge meter and preparation effect identify active casts without permanent ground reticles. Controller: `scripts/held_cast.gd`.

| Working example | Behaviour |
| --- | --- |
| Diamond Scout — Pitch | Tap 22 damage; 1.1s charge up to 40.7 damage and 1105 speed. |
| Stormscribe — Spark Script | Tap 19 damage; 1.2s charge up to 34.2 with a larger spark. |
| Star Navigator — Seeking Orb | Charge up to 1.4s for 27–44.6 damage, larger missile and splash; Twin Stars still fires two. |
| Fairway Ranger — Chip Shot | 1.4s backswing moves marker from 85 to 330 reach; release for 28–42 damage, with existing fragments. |
| Vesper — Comet Seal | Summon a comet from the sky: 1.5s charge, 32–56 damage and 85–119 explosion radius. |
| Alderjaw — Tail Slap | Charge up to 1.3s for stronger push and stun, up to 160 push and about 2s stun. |
| Mara Dawnblade — Sword Cut | Tap 28; 1s charge up to 46.2 and 70 knockback. Bleed remains. |
| Caelum Mirrorwright — Silver Shatter | Three piercing shards; each tap shard hits for 12, or up to 19.2 after 1.2s charge. Twin Self echoes the fan at 60%. |

## 3. Attack types you can choose

The following tables list every base attack style used by the installed heroes. Example descriptions are current working behaviours; numeric details belong to that example, not a requirement for all new heroes. `name`, `description`, `damage` and `cooldown` are common fields and are omitted from the example-fields column.

### Close attacks and travelling melee

| Style id | What it does in a working kit | Example and fields |
| --- | --- | --- |
| `identity_strike` | Headbutt with a close pair of horn impacts: 28 damage, 82 reach, 70-degree arc. | [Young Ram — primary](content/characters/ram.json). `range`, `speed`, `color`, `arc_degrees`, `visual` |
| `melee` | Directional close hit; choose a supported visual. | [Diamond Scout — secondary](content/characters/baseball.json). `range`, `arc_degrees`, `visual`, `color` |
| `slash` | Directional close weapon arc. | [Frostguard — primary](content/characters/goalie.json). `range`, `speed`, `arc_degrees`, `color` |
| `kick` | Directional close kick; can apply authored hit statuses. | [Quarantine Medic — primary](content/characters/medic.json). `range`, `speed`, `arc_degrees`, `color`, `poison_damage`, `poison_duration` |
| `charge` | Rush forward; hit each foe once along the travelled route. | [Young Ram — secondary](content/characters/ram.json). `range`, `speed`, `color` |
| `stomp` | Instant circular impact centred on the caster. | Instant-impact variants. Young Ram now uses `ram_quake`. `radius`, `color` |
| `cat_sweep` | Sweep your claws around yourself over 0.6s. Each enemy within 128 reach takes 43 damage once when the moving sweep reaches it. Walls block the swipe. | [Crossroads Cat — secondary](content/characters/cat.json). `range`, `speed`, `color` |
| `dawn_circle` | Unleash a bright circular sword sweep for 48 damage within 115 units. A golden boundary, blade trails and radiant burst show its full attack area. | [Mara Dawnblade — special](content/characters/dawnblade.json). `range`, `radius`, `color` |
| `twin_fang` | Two quick directional katana cuts, 0.14 seconds apart. Each deals 12 damage within 95 reach; aim both cuts when you start the attack. | [Kage Moonstep — primary](content/characters/kage.json). `range` |
| `beaver_bite` | Snap your incisors at enemies directly ahead within 90 units. | [Alderjaw — primary](content/characters/beaver.json). Kit uses code defaults. |
| `tail_slap` | Sweep a broad paddle tail ahead: 26 damage, knockback and a 1.2s stun. Reach: 120. | [Alderjaw — secondary](content/characters/beaver.json). Kit uses code defaults. |
| `chain_sweep` | Extend a flail, sweep it through a 120-degree arc, then reel it back. Each enemy can take 22 damage once per swing; walls stop the chain. Successive swings alternate direction. The chain itself slows enemies it crosses by 30% for 1.5 seconds, without dealing flail damage. | [Rook Ironhand — primary](content/characters/rook.json). `range`, `arc_degrees`, `follow_bonus` |
| `grapnel_rush` | Throw a grapnel, then pull yourself smoothly up to 260 units forward. Enemies crossed take 18 damage and a 0.6-second stun. Walls stop your travel; this grants no invulnerability. Each enemy hit also loses 2 HP, healing Rook for 2 HP (once per enemy per rush). | [Rook Ironhand — secondary](content/characters/rook.json). `range`, `stun_duration` |
| `body_bounce` | Bounce your whole body quickly between up to three different enemies: 28 damage each. First target within 350 units; later jumps within 260. Walls stop travel. You can still take damage. | [Dribble — secondary](content/characters/basketball.json). `range`, `jump_range`, `jumps`, `speed`, `color` |
| `tumble_pour` | Hop three times along a 240-unit path in 0.9s, leaving three 3s poison puddles. Landing hits deal 12 damage once per foe; puddles poison for 1 damage/s. Walls stop you; you remain vulnerable. | [Tumblebrew — secondary](content/characters/teapot.json). Kit uses code defaults. |

### Projectiles, beams and returning attacks

| Style id | What it does in a working kit | Example and fields |
| --- | --- | --- |
| `projectile` | Traveling shot, stopped by its first hit or a wall; count/spread can create a volley. | [Diamond Scout — primary](content/characters/baseball.json). `range`, `speed`, `color` |
| `homing` | Traveling shot steers toward a foe; optional impact splash. | [Star Navigator — secondary](content/characters/navigator.json). `range`, `speed`, `duration`, `reduction`, `reflect`, `color`, `splash_radius`, `splash_damage`, `spread` |
| `beam` | Immediate piercing line along the aim. | [Living Book — special](content/characters/book.json). `radius`, `color` |
| `ricochet_projectile` | Traveling stone bounces to another nearby foe; Reed’s passive adds a bounce. | [Reed of Silverfall — secondary](content/characters/ferryman.json). `range`, `speed`, `count`, `spread`, `color`, `bounce_range`, `bounce_scale` |
| `return_disc` | Disc travels outward, pauses, then returns; each target can be hit on each leg. | [Vesper — primary](content/characters/vesper.json). `range`, `speed`, `color` |
| `burst_projectile` | Fire four seeds consecutively along your aim in a short burst. Each deals 5 damage; equipment bonuses are divided across the burst. | [Sunpetal — primary](content/characters/sunflower.json). `count`, `spread`, `range`, `speed`, `color`, `bonus_split`, `burst_interval` |
| `spiral_shot` | Fire a curving spiral dart for 20 damage. Alternate its curve with each shot. | [Spindle — primary](content/characters/spindle.json). `range`, `speed`, `curve`, `color` |
| `cross_shot` | Fire four bolts in a cross: one toward your aim, one behind and one to each side. Each deals 14 damage. | [Patch — primary](content/characters/patch.json). `range`, `speed`, `color` |
| `split_lance` | Fire a 20-damage lance. After 150 units it splits into two diverging 13-damage bolts. | [Prism Mage — primary](content/characters/elara.json). `range`, `speed`, `split_distance`, `color` |
| `charged_beam` | Charge for 2.5 seconds, then fire a wide beam for 120 damage. Move slowly while charging; stunning interrupts it. | [Sunpetal — special](content/characters/sunflower.json). `charge`, `width`, `range` |
| `fire_breath` | Breathe a narrow 24-degree stream of fire up to 170 units. Four ticks deal 4 damage each; hits refresh a burn for 1 damage per second over 3 seconds. | [Aurel — primary](content/characters/aurel.json). `duration`, `range`, `arc_degrees`, `burn_damage`, `burn_duration`, `color` |
| `flame` | Repeated short flame-cone hits during a channel; Emberwright also applies burn. | [Emberwright — secondary](content/characters/welder.json). `range`, `arc_degrees`, `duration`, `tick`, `color` |
| `tea_shot` | Pour two curling tea drops for 9 damage each. Hits poison for 1 damage per second over 4s; poison refreshes rather than stacks. | [Tumblebrew — primary](content/characters/teapot.json). `range`, `speed` |
| `corkscrew_key` | Throw a visibly twisting key that pierces up to 2 enemies. Each enemy can only be hit once; walls stop the key. | [Nera Lockstep — primary](content/characters/nera.json). `range`, `speed`, `amplitude`, `wavelength`, `color` |
| `ribbon_stitch` | Send two intertwining living ribbons forward. Each deals 15 damage once; walls stop the weaving threads. | [Pippa Fernwhisker — primary](content/characters/pippa.json). `range` |
| `rune_hammer` | Throw a spinning rune hammer for 24 damage. Walls stop it. Splash reaches 65 units around the impact. | [Garrick Runebearer — primary](content/characters/garrick.json). `range`, `speed`, `splash_radius`, `splash_damage` |
| `facet_spear` | A crystal spear pierces up to two enemies for 25 damage each. Walls stop it. | [Caelum Mirrorwright — primary](content/characters/caelum.json). `range`, `speed` |
| `lantern_comet` | A weaving lantern shot deals 26 damage and flies for about 4 seconds (1200 reach), giving you time to redirect it. Records the last four firing positions. | [Wanderlight — primary](content/characters/wanderlight.json). `range`, `speed` |
| `windwheel` | Throw a spinning shuriken that deals 24 damage on the outward leg, then curves back to you for 16 return damage. Each enemy can be hit once per leg. Walls stop it. | [Kage Moonstep — secondary](content/characters/kage.json). `return_damage`, `range` |
| `lunar_loom` | Two luminous wings sweep out and meet, linger for 1 second in a 60-unit field (6 damage each 0.25s), then split and return to you. Outward and returning passes each hit once for 18 damage. Walls block damage. | [Velvetwing — special](content/characters/velvetwing.json). `range`, `duration`, `color` |
| `scatterlight` | Fire seven thin red lasers in a 36-degree cone, 6 damage each. Each ray stops at its first enemy or wall. Maximum 42 damage when every ray hits one target. | [The Agent — primary](content/characters/agent.json). `range` |
| `time_dart` | Fire a clock needle for 19 damage. A hit stores that foe’s position for 4s, up to 3 marked foes. Repeated hits refresh the mark without replacing its first position. | [Chronicle Keeper — primary](content/characters/chronicle.json). `range`, `speed`, `color`, `rewind_mark` |

### Ground attacks, traps and area control

| Style id | What it does in a working kit | Example and fields |
| --- | --- | --- |
| `target_aoe` | Lob a projectile to the chosen ground spot, then explode; optional secondary fragment bombs. | [Fairway Ranger — secondary](content/characters/golfer.json). `range`, `blast_radius`, `color`, `travel_speed`, `fragment_count`, `fragment_damage`, `fragment_radius`, `fragment_distance` |
| `ice_wall` | Lob an ice projectile, then create a damaging, slowing ice area on landing. | [Frostguard — special](content/characters/goalie.json). `radius`, `duration`, `color`, `travel_speed`, `range`, `blast_radius`, `slow_duration` |
| `manual_mines` | Clicks one and two plant a mine nearby in your aim direction. Click three detonates both for 38 damage each within 95 units. Mines expire after 12 seconds. | [Bracken of Moonburrow — primary](content/characters/bracken.json). `range`, `radius`, `duration`, `color` |
| `ground_sequence` | Three ground eruptions advance along your aim. Each deals 12 damage and slows enemies for 1.5 seconds. | [Bracken of Moonburrow — secondary](content/characters/bracken.json). `count`, `spacing`, `interval`, `radius`, `slow_duration`, `color` |
| `meteor_shower` | Trace a glowing constellation ahead of you. Seven telegraphed meteors fall in sequence, each exploding for 24 damage within 65 units. | [Aurel — special](content/characters/aurel.json). `range`, `radius`, `blast_radius`, `count`, `interval`, `color` |
| `rolling_snow` | A growing snowball explodes on impact: 22–58 damage, knockback, and six small snowballs dealing 5 damage each. | [Snowdrift — special](content/characters/snowman.json). `range`, `speed` |
| `pulse_wave` | An expanding sound ring deals 14 damage once and slows enemies by 25% for 1.6 seconds. | [Backbeat — primary](content/characters/drum.json). `radius`, `wave_speed`, `slow_duration`, `slow` |
| `pulse_burst` | Three expanding pulses deal 8 damage each and erase hostile projectiles. An enemy hit by all three pulses from this cast burns for 3 damage per second for 3 seconds. | [Backbeat — secondary](content/characters/drum.json). `radius`, `wave_speed`, `clear_projectiles`, `tempo_burn` |
| `waterfall_wave` | A rushing waterfall expands around Reed, dealing 48 damage, pushing enemies away and slowing them for 3 seconds. | [Reed of Silverfall — special](content/characters/ferryman.json). `radius`, `wave_speed`, `slow_duration`, `slow`, `knockback`, `color` |
| `orbit_shards` | Three shards circle you for 2.4 seconds. Each shard can hit each enemy once for 10 damage. | [Spindle — secondary](content/characters/spindle.json). `duration`, `radius`, `count` |
| `spiral_shards` | Three glass shards spiral outward from your casting spot for 2 seconds, reaching 250 units. Each shard can hit each enemy once for 14 damage; walls stop shards. | [Prism Mage — secondary](content/characters/elara.json). `duration`, `radius`, `color` |
| `vortex_field` | Create a vortex ahead of you for 3 seconds. It pulls and slows enemies, dealing 8 damage every half-second. | [Spindle — special](content/characters/spindle.json). `duration`, `radius` |
| `chalk_grid` | Draw a 300 by 220 grid ahead for 4s. Enemies inside move 35% slower and take 7 damage every half-second. Walls block its damage. | [Iris Chalkbinder — special](content/characters/iris.json). `range`, `duration` |
| `timber_fall` | An upright tree shakes and falls over 1.1s, striking a 380-unit line for 65 damage and a 1.8s stun. Walls stop the fall; enemies can escape the warning. | [Alderjaw — special](content/characters/beaver.json). Kit uses code defaults. |
| `bitter_bloom` | Place a giant brewing cup up to 220 units ahead. After 1s it erupts across a 150-unit radius for 38 damage and poison (2 damage/s for 4s). Walls block the splash. | [Tumblebrew — special](content/characters/teapot.json). Kit uses code defaults. |
| `fault_steps` | Raise three successive stone faults ahead. Each enemy can take 24 damage only once per cast. | [Cairnheart — primary](content/characters/cairnheart.json). `range` |
| `stone_hoist` | Lift the nearest aimed enemy within 220, briefly stunning it. After 1.2 seconds the cairn collapses for 36 damage within 85. | [Cairnheart — secondary](content/characters/cairnheart.json). `range` |
| `rolling_rampart` | Send a 240-unit-wide rampart forward. It hits each enemy once for 62 damage and pushes them back. Walls stop it. | [Cairnheart — special](content/characters/cairnheart.json). `range` |
| `thunder_procession` | Three storm clouds travel forward in sequence. Each strikes each enemy once for 28 damage with visible lightning. | [Cloudloom — special](content/characters/cloudloom.json). `range` |
| `spectral_tram` | Mark ghost rails for 0.75 seconds, then send a wide spectral tram forward. It hits each enemy once, knocks them away and stuns for 0.75 seconds. Buildings stop the tram. | [Nera Lockstep — special](content/characters/nera.json). `range` |
| `eightfold_eclipse` | Mark a moon-circle ahead. After a 0.3s warning, eight shuriken spiral inward over 1.2s. Each enemy can take up to three 12-damage star hits; the center then bursts for 18 damage in a 90 radius. Walls block the stars. | [Kage Moonstep — special](content/characters/kage.json). `range` |
| `triune_verdict` | Mark a spot ahead. After warnings: a 24-damage hammer seal knocks foes back; a 28-damage crosscut slows; a 38-damage final ring stuns for 0.65s. Each strike has its own area; walls block damage. | [Garrick Runebearer — special](content/characters/garrick.json). `range` |
| `time_bubble` | Place a 130-radius hourglass field up to 250 ahead. For 2s it slows foes by 30% and holds up to 6 moving hostile bullets. Then burst for 40 damage plus 4 per held bullet (maximum 64). Walls block the field; lobbed bombs and beams are not captured. | [Chronicle Keeper — special](content/characters/chronicle.json). `range`, `radius`, `duration`, `slow`, `color` |

### Healing, protection, summons and transformations

| Style id | What it does in a working kit | Example and fields |
| --- | --- | --- |
| `heal_wave` | Heal the caster and nearby allies in a wave. | [Quarantine Medic — secondary](content/characters/medic.json). `range`, `speed`, `duration`, `reduction`, `reflect`, `color` |
| `heal_zone` | Stationary field that heals the caster and allies, never enemies. | [Crosswind Striker — special](content/characters/soccer.json). `duration`, `radius`, `heal_per_tick`, `color` |
| `block` | Temporary damage reduction and projectile block; reflected shots are optional. | [Frostguard — secondary](content/characters/goalie.json). `range`, `speed`, `duration`, `reduction`, `reflect`, `color` |
| `stealth` | Become hidden briefly, with healing; attacks break hiding. | [Crossroads Cat — special](content/characters/cat.json). `radius`, `duration`, `heal`, `color` |
| `summon` | Create temporary friendly minions with their own movement and attacks. | [Dribble — special](content/characters/basketball.json). `radius`, `duration`, `count`, `minion_speed`, `minion_sprite`, `color` |
| `chill_aura` | For 4 seconds, nearby enemies move 45% slower and you take 30% less damage. | [Snowdrift — secondary](content/characters/snowman.json). `duration`, `radius`, `slow`, `reduction` |
| `bloom_seed` | Lob a seed at your aimed spot. It plants, blooms after 3 seconds, then fires 8-damage fireballs at nearby enemies and heals you/allies for 3 HP per second within 140 units for 8 seconds. Maximum two plants per hero. | [Sunpetal — secondary](content/characters/sunflower.json). `range`, `bloom_delay`, `duration`, `heal`, `radius`, `shot_interval` |
| `fern_double` | Grow a leaf double for 3 seconds to lure nearby enemies. It explodes for 24 damage within 150 units and slows drawn-in enemies for 3 seconds. It then pulses yellow, healing you and allies within 150 units for 8 HP each second for 3 seconds (24 total). Never heals enemies. | [Pippa Fernwhisker — secondary](content/characters/pippa.json). `range`, `radius`, `slow_duration`, `slow_factor`, `heal`, `heal_duration` |
| `maypole_waltz` | Plant a maypole ahead. Three ribbon tips spiral outward over 2.4s to a 230-unit radius. Each tip hits each foe once for 36 and slows for 2s. Walls block the ribbons. | [Pippa Fernwhisker — special](content/characters/pippa.json). `range` |
| `rune_cycle` | Each use grants the next rune for 4.5s: Might (+20% damage), Stride (+30% movement), then Ward (35% less damage taken). Only one rune is active at a time. The next rune is shown beside you. | [Garrick Runebearer — secondary](content/characters/garrick.json). `duration` |
| `missile_volley` | Launch four guided missiles in a short volley. Each travels visibly, turns toward a foe and deals 14 direct damage plus 6 splash to other foes within 58 units. Walls stop missiles. | [Bolt Ironcore — secondary](content/characters/robot.json). Kit uses code defaults. |
| `saw_transform` | Fold into a giant spinning saw for 6s (0.45s to transform). Touching the 78-unit blade deals 12 damage every 0.3s. Move at 42% speed; no dodge or normal attacks. Primary becomes Shock Stomp: 16 damage within 170, 0.4s stun then 2.5s slow, with a 2.6s cooldown. Take 30% less damage while transformed. Each enemy you defeat during the form adds 1 second to its remaining duration. | [Bolt Ironcore — special](content/characters/robot.json). `contact_damage`, `reduction` |
| `pocket_rain` | Send a small cloud forward; it pauses, then releases three aimed raindrops for 8 damage each. | [Cloudloom — primary](content/characters/cloudloom.json). `range` |
| `tailwind_seam` | Weave a 400-unit wind lane for 4 seconds. Allies crossing it gain 30% speed; enemies take 7 damage each second. | [Cloudloom — secondary](content/characters/cloudloom.json). `range` |

### Marks, movement, redirection and unusual kits

| Style id | What it does in a working kit | Example and fields |
| --- | --- | --- |
| `magnet_pin` | Fire a magnetic pin for 18 damage. Anchors last 8 seconds; keep two, or three with your level-five passive. | [Polarity — primary](content/characters/magnet.json). `range`, `speed` |
| `magnet_pull` | Pull enemies near your anchors toward them, dealing 22 damage and briefly slowing them. | [Polarity — secondary](content/characters/magnet.json). `radius` |
| `magnet_wire` | Link every owned anchor for 3 seconds. The network deals 9 damage every half-second; crossing wires do not multiply damage. Missing anchors are placed ahead. | [Polarity — special](content/characters/magnet.json). Kit uses code defaults. |
| `echo_brand` | Fire a brand: 40% of its damage on contact, the rest after 1.2 seconds. Enemy movement before the echo adds up to 14 damage. Repeated hits strengthen an existing brand without restarting its timer. | [Veyra Spellthief — primary](content/characters/veyra.json). `range`, `speed` |
| `spell_snare` | Place a snare at your aim. For 2.5 seconds it catches up to six moving enemy shots, then returns them as 14-damage friendly bolts toward nearby foes. It cannot stop floor attacks or lobbed explosions. | [Veyra Spellthief — secondary](content/characters/veyra.json). `range`, `radius`, `duration` |
| `soul_ledger` | Bind up to four nearby enemies for 5 seconds, dealing 10 damage each. Damage dealt to one spreads 25% to the other linked enemies, capped at 12 per shared hit. Shared damage never triggers another share. | [Veyra Spellthief — special](content/characters/veyra.json). `range`, `duration` |
| `rune_slash` | A close sword cut deals 24 damage and leaves a rune at your feet. Keep up to 3 runes for 10 seconds; every third cut gains 10 damage. | [Rune Duelist — primary](content/characters/rune_duelist.json). `range`, `arc_degrees`, `color` |
| `rune_step` | Teleport to your oldest attack rune within 480 units, damaging enemies along the clear route for 28. If that rune is unreachable, make a short forward step instead. | [Rune Duelist — secondary](content/characters/rune_duelist.json). `range`, `color` |
| `rune_domain` | Connect your runes into a glowing court for 2.5 seconds. Enemies inside take 10 damage every half-second. Missing runes are formed around you. | [Rune Duelist — special](content/characters/rune_duelist.json). `duration`, `color` |
| `blink_bomb` | Teleport up to 280 units along your aim, stopping before walls. Leave a glowing bomb at your old position; after 1 second it explodes for 62 damage within 115 units. | [Bracken of Moonburrow — special](content/characters/bracken.json). `range`, `radius`, `fuse`, `color` |
| `page_channel` | Hold secondary to open the book and release seeking pages every 0.22s, each for 11 damage. Alternate nearest-target pages with a rotation through other visible enemies in range. You cannot move or dodge and take 30% more damage while open. Release to stop. | [Living Book — secondary](content/characters/book.json). `range`, `speed`, `color` |
| `vacuum_intake` | Hold primary for a close intake: 12 damage every 0.7 seconds and a 1-second slow. Within the first 0.4 seconds it can catch one hostile projectile. Release to fire it where you aim for 36–60 damage. Stored shots release automatically after 6 seconds. | [Dustdevil — primary](content/characters/dustdevil.json). `range` |
| `brush_crush` | Swing the brush across a close 110-degree arc, dealing 38 damage within 100 units. | [Dustdevil — secondary](content/characters/dustdevil.json). `range` |
| `grand_draw` | Channel a visible 320-unit vacuum cone for 2.5 seconds, pulling enemies towards the nozzle for a follow-up Brush Crush. Walls stop pulling; bosses are pulled less. | [Dustdevil — special](content/characters/dustdevil.json). `range` |
| `compass_turn` | Redirect flying lanterns and infuse them with your current element. Earth: 12 splash damage, poison 2/s for 4s; roots grow after 2s and slow by 45% for 8s after growing. Fire: 20 splash damage and burn 3/s for 4s; lava lasts 8s and renews burn on contact. Both have 85 radius. Starts as Earth. With no flying bolts, launch an infused 16-damage light. | [Wanderlight — secondary](content/characters/wanderlight.json). Kit uses code defaults. |
| `walking_chronicle` | Replay your last four shots from their original positions, 0.25s apart at 65% damage. After the last replay, switch Earth to Fire or Fire to Earth for future redirections. Starts as Earth. Walls block shots. | [Wanderlight — special](content/characters/wanderlight.json). Kit uses code defaults. |
| `corner_lens` | Deploy a floating lens for 5 seconds. Shotgun rays touching it bend toward a nearby enemy within 360 reach at 80% damage. Place it to create new firing angles; walls still stop the rays. | [The Agent — secondary](content/characters/agent.json). `range` |
| `agent_ambush` | Aim at an enemy. Three circles behind it flash twice across a 120-degree arc. An agent appears in each, charges for 1 second, then fires a 32-damage beam through enemies and walls. Three beams total; they aim at the target when firing. | [The Agent — special](content/characters/agent.json). `range` |
| `pact_needle` | Send a traveling green needle that marks the first enemy it hits for 4 seconds. Marks guide Gathering Knot and your converted ally. | [Thistlebond — primary](content/characters/thistlebond.json). `range` |
| `gathering_knot` | Aim at ground. A glowing knot winds up for 0.45 seconds, then draws marked enemies within 240 reach toward it, dealing 24 damage and slowing them by 35% for 2 seconds. Bosses take damage and slow but cannot be pulled. | [Thistlebond — secondary](content/characters/thistlebond.json). `range` |
| `change_of_heart` | Turn a visible non-boss enemy into an ally for 8 seconds, or until defeated. It keeps its appearance and melee/ranged role, with up to 90 health and balanced attacks. One ally at a time. Conversion grants normal defeat rewards once and counts toward clearing the room; expiry gives no further XP. Cannot convert players or training targets. | [Thistlebond — special](content/characters/thistlebond.json). `range` |
| `rewind_chime` | Consume your marks within 550 reach: each foe takes 24 damage, is stunned for 0.5s and slides back toward its recorded position. Walls stop the rewind; bosses take damage and stun but cannot be moved. | [Chronicle Keeper — secondary](content/characters/chronicle.json). `range`, `stun_duration`, `color` |

### Additional specialised patterns

| Style id | Working behaviour | Example and fields |
| --- | --- | --- |
| `chain` | Immediately bounce damage between different nearby targets. | [Fairway Ranger — special](content/characters/golfer.json). `range`, `jump_range`, `jumps`, `color` |
| `latchline` | Fire a chained hook that pulls its first enemy up to 140 units toward you and stuns it for 1.5 seconds. Bosses are pulled a shorter distance. Walls block the chain. | [Nera Lockstep — secondary](content/characters/nera.json). `range`, `speed`, `color`, `stun_duration` |
| `iron_haul` | Send a hooked chain down a marked lane. Catch up to four enemies for 12 damage and a brief slow, drag them back, then deal 38 damage as the chain returns. Bosses resist the pull. In PvP, players are pulled at half speed. | [Rook Ironhand — special](content/characters/rook.json). `catch_damage`, `range`, `width`, `max_targets` |
| `chalkstroke` | Draw a 250-unit chalk line over 0.45s. It lasts 4s and damages each enemy touching it once for 16. Keep up to three lines; walls stop the drawing. | [Iris Chalkbinder — primary](content/characters/iris.json). `range`, `duration` |
| `erase_release` | Erase your chalk lines. Each releases two seeking chalk shards for 12 damage each. With no lines, release one shard. | [Iris Chalkbinder — secondary](content/characters/iris.json). Kit uses code defaults. |
| `piston_jab` | Extend a mechanical fist at foes directly ahead: 30 damage within 100 units. | [Bolt Ironcore — primary](content/characters/robot.json). Kit uses code defaults. |
| `mirror_fan` | Release three piercing silver shards in a broad fan. Hold up to 1.2s to enlarge and strengthen them; each foe can take one hit per shard. Twin Self echoes the cast. | [Caelum Mirrorwright — secondary](content/characters/caelum.json). `range`, `speed`, `hold_charge` |
| `twin_self` | For 6 seconds, your identical reflection copies your movement, aim, primary and secondary attacks (60% damage). It has 60% of current HP, capped at 66. If either body falls, continue with the survivor; losing both defeats you. | [Caelum Mirrorwright — special](content/characters/caelum.json). `duration` |
| `threaded_needles` | Two silk needles converge ahead of you, then cross and spread apart. 12 damage per needle; 440 reach. | [Velvetwing — primary](content/characters/velvetwing.json). `range`, `speed`, `color` |
| `silk_tripline` | Weave three silk lines ahead of you. They arm after 0.6s and last 4s. A crossing enemy snaps a line for 22 damage and a 2s slow. Each enemy is caught once per cast. | [Velvetwing — secondary](content/characters/velvetwing.json). `range`, `duration`, `color` |

### Other supported basic aliases and internal attacks

| Style | Use |
| --- | --- |
| `punch`, `scratch` | Basic close directional attack, alongside `melee`, `slash` and `kick`. Use `range` and `arc_degrees`. |
| `spin` | Basic circular melee impact; `cat_sweep` is the animated moving sweep variant. |
| `trap` | Place a trap ahead; detonates on contact. Copy the trap dispatch in `game.gd`/`arcade.gd` before authoring. |
| `saw_stomp` | Bolt Ironcore’s primary while transformed. Internal form attack, not a separate normal hero slot. |

### River tricks and frontline protection

These kits live in `scripts/v75_heroes.gd`. All effects have actor limits, obey walls, reset between runs, and replicate as host-owned snapshots.

| Style | What it does | Example / fields |
| --- | --- | --- |
| `water_jet` | Three short pulses over 0.24s; total listed damage. The nearest target or wall stops each pulse. | Ripplejaw primary; `range`, `damage` |
| `fish_splash` | Immediate circular splash, then exactly three slowing puddles. A recast replaces the previous puddles. | Ripplejaw secondary; `radius`, `puddle_radius`, `puddle_duration` |
| `tidal_maw` | Aim toward a foe. A shadow follows slowly, then locks before a large bite after 2s; area damage, stun and inward pull. Bosses resist displacement. | Ripplejaw special; `range`, `radius`, `stun_duration`, `pull` |
| `shoal_vortex` | Fixed whirlpool, 0.8s warning and six ticks over 3s; pulls and slows, no stun. Listed damage is the total of all six ticks. | Ripplejaw final technique; `range`, `damage` (125 radius) |
| `hearth_combo` | Two close hammer swings, then a wider third swing for 150% damage and knockback. A 1.8s pause resets the sequence. | Hearthwarden primary; `damage`; kit has fixed reaches/angles |
| `rally_banner` | One planted banner protects its owner and allied players within line of sight. A mobile alternative follows its owner. | Hearthwarden secondary; `duration`, `radius`, `reduction`, `mobile_banner` |
| `shield_march` | A moving shield front hits each foe once, pushes and slows, and catches up to six moving hostile projectiles. Beams and lobbed explosions bypass it. | Hearthwarden special; `width`, `damage`; fixed 2.4s travel |
| `forgefall` | Three visible anvils land in a line after a warning. Each 65-radius impact uses the listed damage and hit statuses. | Hearthwarden final technique; `damage`, `stun_duration` |

### Complete replacement patterns for final mastery

These shared renderers are available for new abilities too. They give a visible attack animation and bounded hit rules.

| Style | Behaviour | Main fields |
| --- | --- | --- |
| `master_fan` | Staggered directional sweeps; each foe is hit once per cast | `range`, `count`, `charge`, `duration` (fixed sweep angles) |
| `master_lance` | Visible charge followed by a piercing lane | `range`, `width`, `charge`, `duration` |
| `master_sigils` | One to five delayed ground circles; a foe can be hit by multiple circles | `range`, `radius`, `count`, `spacing`, `charge`, `duration` |
| `master_fountain` | Stationary field; damages foes and optionally heals allies every 0.5s | `range`, `radius`, `duration`, `heal`, status fields |
| `master_pincer` | Two curved wings travel out and return; once per foe per leg | `range`, `width`, `duration` (allow at least 1.6s; fixed hit radius) |
| `master_chain` | Delayed links to up to five different visible foes | `range`, `count`, `duration` (fixed 0.25s start, 0.2s link spacing) |

All six use `damage`, `cooldown`, `color` and optional `visual_texture`. They accept implemented burn, bleed, poison, stun and slow hit fields. See [Mastery Authoring Guide](MASTERY_AUTHORING_GUIDE.md) for the full schema and timing rules, and [Final Mastery Catalogue](FINAL_MASTERY_CATALOG.md) for every hero’s current alternative.

### Burrowing and rift geometry

| Style | What it does | Example / tuning |
| --- | --- | --- |
| `gopher_claw` | Two close swipes 0.14s apart; stop and surface for 0.32s. Each hit has a 40% chance of 3s bleed (2 damage/second). | Burrowick primary; 18 damage per swipe, 80 reach / 100-degree arc |
| `gopher_dive` | Burrow along a clear path for 0.55s, surface short of the target, splash damage and stun. | `range`, `radius`, `stun_duration`; no wall traversal |
| `gopher_cave` | Telegraph and collapse the owner's last four completed tunnel segments. Intersections hit once per cast. | `width`, `damage`, `slow_duration`, `slow` |
| `gopher_fault` | Replace history-dependent cave-in with one aimed 340-range fissure. | Burrowick final technique |
| `rift_pin` | Place one of two pins at the clicked point, clamped by walls and range; the connecting seam flashes damage. New casts replace the oldest pin; pins over 600 apart lose their link. | `range`, `link_multiplier`; very small pin impact |
| `rift_rotate` | Sweep the two-pin seam through 90 degrees over 0.6s, hitting each foe once. | `width`, `damage`; requires two pins |
| `rift_triangle` | Freely aim a triangle within 500 range. It rotates 180 degrees over 1.2s while its edges fire in sequence; graphics and damage use the same rotating edges. | `range`, `radius`, `damage` per edge |
| `rift_scatter` | Three delayed, independently warned rift bursts in a fan. | Nullweaver final special; 60-radius bursts |

Burrowick uses short 0.95s digging strokes. Direction is committed for each stroke; the final 24% is a surface pause to choose the next direction. Digging moves at 80% of base speed while active (about 118 units per full stroke at speed 205). Attacking forces a stop and surface except during Pounce's explicit dive. Pounce retains 560 reach. The four numbered trail sections are the exact Cave In preview, including the current section; crossing enemies are slowed by 20%. Guest clients receive the host's phase clock, history and attack locks.

`packed_earth` grants 12% protection for 2s after Pounce; `needle_frost` adds a 1s, 20% slow to Nullweaver's hits. Both unlock at level 5. These mechanics require `v78_heroes.gd`; copying the names alone will not implement them.

### Lava travel and momentum gliding

| Style | Behaviour | Fields / working example |
| --- | --- | --- |
| `magma_breath` | A narrow, short lava burst with a burn and two ground patches. | Molten Pilgrim primary; 130 reach, 64-degree arc, `damage` |
| `shell_lob` | Move the caster to the aimed point over a visible 0.8s arc; impact damages and leaves lava. | `range`, `damage`; 100 impact radius. Normal movement/attacks lock during flight; no invulnerability. |
| `back_volcano` | A mobile six-second eruption; two randomly aimed, visibly arcing lava balls every 0.5s. | `damage` per impact; landing patches stay for 4s. |
| `caldera_ring` | Warn for 0.75s, then erupt eight patches in a ring. Overlaps hit each enemy once. | Molten Pilgrim final special; `damage`; 120 ring radius. |
| `sail_needle` | A fast non-piercing projectile gains up to 12 extra damage from actual movement speed. | Kite Corsair primary; `damage`, `range`; maximum momentum at 280 speed. |
| `windlass_swing` | Orbit the aimed wind anchor, accelerating from incoming momentum to 480 speed; hold secondary to keep orbiting (up to 4s), then release to launch toward the current aim. Each foe can be hit once. | `range`, `damage`; travel respects walls. |
| `storm_delivery` | Three parachute parcels drop with staggered warnings, splash damage and outward knockback. Leave friendly wind pads. | `range`, `damage` per parcel; 70 impact radius. |
| `headwind_harpoon` | Non-piercing shot pulls a hit foe 35 closer and slows it by 40% for 1.5s. | Kite Corsair final primary; `damage`, `range`; no momentum damage. |

**Ground lava:** 3 damage every second. Furnace Breath and Shellbound also apply a separate mild 1-per-second burn for 3s on impact. Overlapping patches belonging to the same hero cannot multiply the direct tick. At most 16 patches per owner and 48 globally; patches expire and disappear when their owner dies. Allied players are excluded.

**Movement design:** Molten Pilgrim crawls at 75 speed and its dodge travels 28% of the normal distance. Its aimed Shellbound is the travel tool. Kite Corsair accelerates toward a desired velocity and banks gradually; releasing movement brakes. Its momentum gauge uses observed travel, so pushing against a wall cannot charge extra projectile damage. Both movement abilities replicate through host state and suppress client walking packets while active.

**New passives/status:** `melting_presence` removes up to 40 *percentage points* from nearby enemies' combined damage reduction, down to zero. A 60% shield becomes 20%, but invulnerability remains intact; multiple snails do not stack the aura. `updraft_reserve` grants 15% protection for 2s after a swing. Both passives unlock at level 5. Friendly wind pads apply `tailwind`: 20% extra movement speed, lasting 1.5s after the latest refresh.

See `scripts/v79_heroes.gd` for the shared implementation and `tools/build_v79_heroes.py` for reproducible data and art. Each hero's JSON has two mastery options on different ability buttons, with explicit trade-offs.

### Water/lightning partnerships, weaving and recorded time

| Style | What it does | Fields / example |
|---|---|---|
| `tide_needle`, `volt_note` | First-hit projectiles apply a 3s water/lightning mark. Opposite marks from a different friendly hero consume the mark for a 10-damage, 85-radius discharge. No self-combos or enemy-team combos. | `damage`, `range`; Tide Keeper / Spark Keeper |
| `tide_fan` | Three water darts, each able to mark and combine. | Per-dart `damage`, `range`; Rain Harp |
| `volt_lance` | Two close-spaced notes; second deals 45% of the first's damage. | `damage`, `range`; Double Overture |
| `sluice_pool`, `relay_field` | Aimed fields pulse once a second. Water slows briefly; friendly water/lightning field overlap adds at most one extra 5-damage pulse per water tick. | `radius`, `duration`, per-pulse `damage`, `range` |
| `tidal_wheel` | A 145-radius waterwheel rolls forward at 65 speed for 4s, pulsing every 0.8s; walls stop its travel. | Per-pulse `damage`, `range` |
| `thunder_score` | Warn, then draw repeated damaging chords from nearby own relays to the aim point. Without relays, create three surrounding origins. Each foe is hit once per pulse even at intersections. | Per-pulse `damage`, `range`; 27 line half-width |
| `shuttle_stitch` | Needle leaves a visible seam toward its maximum reachable endpoint; only the latest seam remains, for 6s. | `damage`, `range`; Running Stitch |
| `seam_ride` | Travel along the available route toward the last seam endpoint, damaging crossed foes once. Without a seam, travel 140 toward aim. Cannot pass walls. | `damage`; max 400 travel |
| `loom_cage` | Five-second diamond field, pulses and 40% slow. | Per-pulse `damage`; 125 radius |
| `loom_fan` | Three non-piercing heavy thread needles. | Per-needle `damage`, `range`; Loose Ends |
| `paradox_split` | Projectile travels to the clicked distance, then splits perpendicular into two shards at 65% damage. An earlier collision cancels the split. Records the latest three casts. | `damage`, `range`; Forked Second |
| `history_rewind` | Retrace up to 3s of recorded movement; hit each crossed enemy once. Does not restore HP or pass walls. | `damage`; Unwritten Footsteps |
| `royal_reprise` | Replay the last three recorded primaries from their origins/directions; no recursive recording. Origins behind walls are skipped. | Per-shot `damage`; Royal Reprise |
| `time_cage` | Four-second clock field with damage pulses and 40% slow. | Per-pulse `damage`; 150 radius |

These patterns live in `scripts/confluence_heroes.gd`. Effects are host-owned and replicated. Per-owner fields are capped at three, global fields at 24, projectiles at 96. A new custom style still requires code; copying an arbitrary name into JSON does not implement an attack.

### Corpse companions and timing counters

| Style | Behaviour | Working example / constraints |
|---|---|---|
| `gravespark` | A straight spirit dart that stops at a foe or wall | Morrow Shepherd primary |
| `raise_remains` | Consume grave markers in an aimed radius to raise temporary allies | Morrow secondary; two melee echoes, a third ranged echo with passive. 18s lifetime; no boss bodies or extra kill XP. Training yard creates practice markers. |
| `life_lattice` | Seven-second health pool with visible red links | Morrow special; pool starts from actual remaining HP. Hits to any body drain it. Lines steal up to 6 HP/s; end split reserves 60% for hero, subject to HP caps. Area damage can hit several bodies. |
| `last_procession` | Summons march to an aimed point, burst and disappear | Morrow final special; 24 damage per echo, small slow area. Replaces protection with offence. |
| `scissor_feint` | Alternating aimed melee crescents with a matching filled hit sector | Glimmer Mantis primary; range and cooldown can trade off |
| `mirror_guard` | A 0.45s, one-hit guard that earns one Poise | Mantis secondary; hit must be at least 5 damage after reductions. Maximum three charges; tiny DoT ticks cannot farm them. |
| `glass_verdict` | Three advancing diamond cuts; one hit per enemy | Mantis special; 42 + 10 per spent Poise, maximum 72 base damage |
| `patient_execution` | A visible 0.8s wind-up followed by a wide close cut | Mantis final special; 88 + 12 per Poise, 18s cooldown. Origin and aim lock at cast. |

Health redistribution is not healing and earns no healing statistics. Summons are separate actors; they never become extra encounter enemies or block room completion. Rendering and multiplayer snapshots include corpses, summons, link bars, parry windows and charge pips.

### Close attacks, field support and curved travel

These are implemented reusable style families in scripts/v90_heroes.gd, dispatched through object_combat.gd. Copy the full corresponding JSON example, then adjust numbers. Visuals and multiplayer snapshots accompany the mechanics.

| Style | Working example | What it does / authoring constraint |
|---|---|---|
| `v90_wing` | Cindervane primary | Two timed close cuts, feather banking capped at three; each hit is separate. |
| `v90_ascent` | Cindervane secondary | Curved collision-safe travel with an extra sprite pose and landing impact. Host owns movement. |
| `v90_phoenix`, `v90_nest` | Cindervane special / final | Pulsed close burst leaves a stationary 5.5s smoke ring: allied heroes inside have a 12% chance to dodge direct hits (not DoT). The final mastery trades this for a healing/damage nest. |
| `v90_reed`, `v90_steps` | Tova primary / secondary | A narrow tongue path and round tip share the exact damage shape; on a hit, heal the most injured nearby ally 2 HP. Secondary leaves timed healing lights. No repeated stacking heal in one tick. |
| `v90_haven`, `v90_guides` | Tova special / final | Stationary protective refuge or two finite lantern helpers. |
| `v91_scissors`, `v90_puppets` | Merrymask primary / secondary | Warned aimed string crossing and two limited melee understudies. |
| `v90_curtain`, `v90_stage` | Merrymask special / final | Warned curtain strike or a larger finite stage companion. |
| `v90_chop`, `v90_pot` | Crumb Cook primary / secondary | Close cleaver and a pot with friendly healing / hostile damage. |
| `v90_feast`, `v90_pepper` | Crumb Cook special / final | Delayed cleansing feast; pepper variant trades healing for burn. |
| `v91_pistol`, `v90_lasso` | Dust Marshal primary / secondary | Visible pistol round; Hogtie deals 18 after a 0.3s throw, smoothly pulls toward a point 48 from the caster over 0.4s, and stuns for 2s. Walls stop the rope/pull. |
| `v90_stampede`, `v90_posse` | Dust Marshal special / final | Collision-safe charge with one hit per target, or finite deputies. |
| `monk_punch` | Tempo Monk melee primary | Three directional jabs at 0 / 0.09 / 0.18 seconds; all three on one target trigger slow. |
| `briar_claw` | Quill Prowler primary | Curved leaf-talons for a close claw hit. |

Cindervane's extra open pose is assets/cindervane_open.png. Keep additional poses optional and keep idle/walk1/walk2/attack mandatory. Companion caps and expiry are gameplay rules, not optional optimisations.

### Bouncing treats and banked projectile counters

| Style | What it does | Working example / parameters |
| --- | --- | --- |
| `wick_fire` | Single visible fireball stops at first target/wall; applies burn | Wick-o'-Wisp: `speed`, `range`, `burn_damage`, `burn_duration` |
| `wick_face` | Forward fan stuns, then slows for three seconds after stun | `range`, `stun_duration`; LOS required; no fear on targets behind the hero |
| `wick_treats` | Two-second radial lob volley; first landing, one bounce, second landing opens a patch | `count`, `range`, landing `damage`; five flavours cycle evenly. `goodies: true` replaces harmful flavours with heal/slow. |
| `crab_pincers` | Two timed short forward claw fans | Cobbleclaw: damage is **per claw**, so add both hits when balancing |
| `crab_shell` | 3.5-second guard catches up to four hostile projectiles | Catch radius 45, 50% guard; bank lasts 12 seconds; only authority removes shots |
| `crab_crush` | Wall-safe scuttle hits once per foe, pushes/slows, spends bank on shards | `range`, contact `damage`; shares host-owned movement and ignores guest position overrides |
| `crab_nursery` | Stationary four-second allied refuge replaces shell catching | `range`; 20% guard, 4 HP/sec plus 1 per banked shot consumed |

Treat patches last three seconds and have distinct icons as well as colour: snowflake = slow, bubbles = poison (2/sec for 2s), flame = burn (3/sec for 2s), lightning = shock (2 per half-second with brief stun each second), cross = allied healing (2 per half-second). Harmful effects refresh while a foe remains inside; no healing of rivals. Walls block landings and field effects. The seasonal module shares a 192-effect cap and off-screen culling; expired effects are removed.

## 4. Buffs, debuffs and control

### Harmful statuses

| Effect | What the player sees | What it does | Fields / implementation |
| --- | --- | --- | --- |
| Burn | Orange indicator | Damage over time | `burn_duration`, `burn_damage`; normally 1 tick/s |
| Bleed | Red indicator | Damage over time | `bleed_duration`, `bleed_damage`; normally 1 tick/s |
| Poison | Purple indicator | Damage over time | `poison_duration`, `poison_damage`; normally 1 tick/s; Velvetwing explicitly uses 0.5s ticks |
| Slow | Blue indicator | Multiplies movement speed | `slow_duration` with `slow_factor` for shared projectiles/lobs; some wave/mastery kits use `slow` instead |
| Stun | White indicator | Stops movement and actions | `stun_duration` in the shared hit helper; some pulse kits use `stun` |

Reapplying the same status normally refreshes the longest duration and strongest value; it does not create unlimited independent stacks. For example, `poison_damage: 2` and `poison_duration: 5` means **2 damage each second for 5 seconds**, normally 10 total. A 0.5s interval doubles the number of ticks unless the per-tick value is adjusted.

Status fields are read by particular attack implementations. Shared projectile impacts and mastery attacks use the standard hit helper; do not assume every bespoke melee/area style reads every status field. Test the style you chose or add the hook to its implementation.

### Other control and beneficial effects

| Choice | Examples | Design rule |
| --- | --- | --- |
| Knockback / pull | Tail Slap, Waterfall Wave, Gathering Knot, Latchline | Check walls; bosses may resist movement. `knockback`/`push` fields are kit-specific. |
| Capture / erase / reflect projectiles | Spell Snare, Triple Tempo, Frostguard block, Dustdevil intake, Borrowed Moment | Decide exactly which moving shots can be caught; beams/floor hazards are separate. |
| Enemy conversion | Change of Heart | Non-boss foes only; one ally for 8s or until killed. Defeat rewards occur once at conversion. |
| Taunt / lure | Fern Double | Redirect eligible enemies; use a visible decoy with a bounded lifetime. |
| Damage reduction | Chill Aura, Ward rune, saw form, Silk Guard | Keep some vulnerability; do not add reductions without a cap. |
| Healing | Heal Wave, Healing Zone, flower/fern fields | Allies only; distinguish spell healing from food/checkpoint healing in statistics. |
| Movement boost | Stride rune, Trailkeeper, Fernstep | Temporary multiplier with an obvious visual. |
| Damage boost | Might rune, Drums of War | A bounded multiplier; show the aura and respect team membership. |
| Hiding / invulnerability | Cat’s stealth, dodges, specific movement skills | They are different mechanics: stealth does not promise immunity. |
| Marks / anchors / roots / lava | Needles, pins, runes, elemental lanterns | A mark is not automatically a debuff. It needs an owning mechanic and an expiry limit. |
| Mirror / summon / transformation | Caelum, Dribble, Bolt | Define ownership, health, expiry, movement, damage and what happens when the copy dies. |

Kit-specific status keys such as `rune_might`, `rune_stride`, `rune_ward`, `fern_stride` and `silk_guard` are internal to their kits. They are not new generic `passive_effect` choices.

## 5. Passive choices

Passives unlock at **hero level 5 during a run**. The description goes in `passive`; the implemented identifier goes in `passive_effect`. A new description alone does not change the code. Many specialised passives depend on their original kit.

| Passive id | Current behaviour | Working hero |
| `candle_light` | Three rotating overlapping circles: allies receive +15% healing and +50% **existing crit bonus**; no added crit chance; multiple auras do not stack | Wick-o'-Wisp |
| `shell_ledger` | +3% damage reduction per banked caught shot, max 12%; ends on spending/expiry | Cobbleclaw |
| --- | --- | --- |
| `heal_on_kill` | Second Wind: recover 4 health on each enemy defeated. | [Young Ram](content/characters/ram.json) |
| `life_steal` | Rebound: heal for 8% of damage dealt. | [Dribble](content/characters/basketball.json) |
| `quick_primary` | Quick Reading: primary cooldown reduced by 20%. | [Living Book](content/characters/book.json) |
| `slow_thorns` | Cold Reprisal: enemies that strike you in melee are slowed for 3 seconds. | [Frostguard](content/characters/goalie.json) |
| `quick_secondary` | Batting Practice: Bat Sweep cooldown is reduced by 20%. | [Diamond Scout](content/characters/baseball.json) |
| `guard` | Tempered Plate: take 10% less damage. | [Emberwright](content/characters/welder.json) |
| `twin_orbs` | Twin Stars: Seeking Orb launches two tracking projectiles. | [Star Navigator](content/characters/navigator.json) |
| `stone_bounce` | River Skipper: each Skipping Stone can bounce once to another nearby enemy. | [Reed of Silverfall](content/characters/ferryman.json) |
| `primary_bleed` | Open Wound: Sword Cut causes bleeding for 2 damage per second for 4 seconds. Repeated hits refresh it. | [Mara Dawnblade](content/characters/dawnblade.json) |
| `stolen_slow` | Quick Study: returned Spell Snare bolts slow their target for one second. | [Veyra Spellthief](content/characters/veyra.json) |
| `war_drums` | Drums of War: you and nearby allies deal 8% more damage within your 200-unit aura. | [Backbeat](content/characters/drum.json) |
| `third_anchor` | Threefold Polarity: keep three magnetic anchors; Live Wire connects all three. | [Polarity](content/characters/magnet.json) |
| `fern_afterglow` | Afterglow: allies healed by Fern Double also gain 20% movement speed for 2 seconds. | [Pippa Fernwhisker](content/characters/pippa.json) |
| `long_orbit` | Balanced Spin: Orbit Dance lasts one extra second. | [Spindle](content/characters/spindle.json) |
| `long_buddies` | Extra Credits: Bit Buddies stay for two additional seconds. | [Patch](content/characters/patch.json) |
| `wide_mines` | Wide Fuse: mine explosions gain 20 units of radius. | [Bracken of Moonburrow](content/characters/bracken.json) |
| `far_refraction` | Far Refraction: outward spirals reach 60 units farther. | [Prism Mage](content/characters/elara.json) |
| `wide_meteors` | Afterglow: meteor explosions gain 12 units of radius. | [Aurel](content/characters/aurel.json) |
| `long_runes` | Lingering Script: your planted runes remain for 5 extra seconds. | [Rune Duelist](content/characters/rune_duelist.json) |
| `purifying_rune` | Purifying Rune: activating Ward removes burn, bleeding and poison from Garrick. | [Garrick Runebearer](content/characters/garrick.json) |
| `master_key` | Master Key: Corkscrew Key can pierce one additional enemy. | [Nera Lockstep](content/characters/nera.json) |
| `fresh_pour` | Fresh Pour: landing on a poisoned foe restores 2 health, once per different foe per Tumble Pour, up to 6 health. | [Tumblebrew](content/characters/teapot.json) |
| `follow_through` | Follow Through: hitting an enemy with Grapnel Rush empowers your next Chain Sweep within 4 seconds, adding 8 damage. | [Rook Ironhand](content/characters/rook.json) |
| `alder_armour` | Alder Armour: each different foe you stun grants 2% damage reduction for 8s, up to 20%. Stunning the same foe refreshes its stack. | [Alderjaw](content/characters/beaver.json) |
| `second_draft` | Second Draft: Erase & Release heals you for 3 health per erased line. | [Iris Chalkbinder](content/characters/iris.json) |
| `overclock_reserve` | Overclock Reserve: three successful Piston Jabs prime the next Missile Volley with one extra missile. Missing a jab gives no charge. | [Bolt Ironcore](content/characters/robot.json) |
| `stormcatcher` | Stormcatcher: Tailwind Seam becomes a visible charged wind lane. It catches up to three hostile moving projectiles, then releases one 10-damage seeking lightning spark per catch. Does not stop floor attacks or lobbed explosions. | [Cloudloom](content/characters/cloudloom.json) |
| `bedrock` | Bedrock: each foe hit by Fault Steps grants 5% damage reduction for 3 seconds, up to 20% per cast. | [Cairnheart](content/characters/cairnheart.json) |
| `clear_sight` | Clear Sight: Silver Shatter also slows enemies it hits for 2 seconds. | [Caelum Mirrorwright](content/characters/caelum.json) |
| `overload` | Overload: every 6 seconds, release a 145-radius poison pulse. Nearby enemies take 3 poison damage per second for 4 seconds. | [Dustdevil](content/characters/dustdevil.json) |
| `soft_landing` | Soft Landing: Silk Tripline surrounds you with a faint orb and grants 15% damage reduction for 2.5 seconds. Enemies that melee-hit you during this protection are poisoned for 2 damage every 0.5 seconds for 3 seconds. | [Velvetwing](content/characters/velvetwing.json) |
| `trailkeeper` | Trailkeeper: Compass Turn grants a 30% movement boost for 1 second. | [Wanderlight](content/characters/wanderlight.json) |
| `moon_thread` | Moon Thread: a returning Windwheel marks enemies for 3 seconds. Your next Twin Fang hit consumes the mark for 8 extra damage. | [Kage Moonstep](content/characters/kage.json) |
| `crossfire_protocol` | Crossfire Protocol: lens-bent shots mark enemies for 3 seconds. Ambush beams deal 5 extra damage to marked enemies. | [The Agent](content/characters/agent.json) |
| `binding_thorns` | Binding Thorns: when at least two living enemies bear your Pact Needle marks, each is poisoned for 2 damage per second for 5 seconds. A lone mark does not apply poison. | [Thistlebond](content/characters/thistlebond.json) |
| `patient_hands` | Patient Hands: Second Needle marks last 6 seconds instead of 4, giving you more time to set up a rewind. | [Chronicle Keeper](content/characters/chronicle.json) |
| `waylight_life` | Allies, including the owner, within 160 reach heal 2 HP on successful direct hits. One heal per 0.75s per hero; no DoT triggers or stacking from multiple Tovas. Walls block the aura. | [Tova of Lanternmarsh](content/characters/tova.json) |
| `slippery_scales` | Every third incoming moving projectile is reflected at 80% damage, capped at 30. Beams and explosions do not trigger it. | Ripplejaw; counter resets each run |
| `steadfast_forge` | Completing the third hammer swing gives 15% damage reduction for 2s, shown by a golden ward. | Hearthwarden; requires its normal combo primary |

For general-purpose starters, use an existing simple passive such as `heal_on_kill`, `guard`, `quick_primary`, `quick_secondary` or `life_steal` where supported. Life steal also needs its authored `passive_amount`. A kit-specific passive must keep the supporting attack or be implemented for its replacement.

Additional passive choices: `sluice_shelter` grants 8% protection to allies inside your water fields; `conductors_step` grants 20% speed while standing in your lightning fields; `hem_guard` grants 10% protection for 1.5s after Seam Ride; `borrowed_moment` grants 20% protection for 1s after rewind. These unlock at level 5.

**Grave Chorus (`grave_chorus`)** raises the summon cap from two to three, makes the third echo ranged and increases summon HP from 42 to 60. **Second Wind (`second_wind`)** heals 8 on a successful timing guard, once per 6 seconds. Both unlock at hero level 5.

## 6. Mastery and alternate abilities

Run levels reset when an adventure ends. **Permanent hero mastery** is separate, saved per hero in the local profile and included in profile export/import.

| Progression | Unlock | Current requirement / effect |
| --- | --- | --- |
| First technique | Optional change to one base ability | 3 clears, 2 different realms, 10,000 damage |
| Crit milestone 1 | Small critical-hit chance | 3 clears: 2% chance for +20% damage |
| Mastery title | Equip a title celebrating that hero | 6 clears, 3 different realms, 20,000 damage |
| Crit milestone 2 | Stronger critical hits | 6 clears: 4% chance for +40% damage |
| Crit milestone 3 | Final crit tier | 9 clears: 6% chance for +60% damage |
| Final technique | Full alternate attack on another button | 12 clears, 6 different realms, 810,000 damage |
| Tuning points | Small play-style investments | First clear of a different realm grants 1 point (earn up to 6). At most 4 invested, at most 2 per category; each has a drawback |

Crit milestones use clears; they do not mean run level 3/6/9. A title unlock and a technique unlock can have additional requirements as shown above. Progress awards and teacher override are handled by `legacy.gd`.

| Tuning choice | Per point benefit | Per point trade-off |
| --- | --- | --- |
| Power | +4% damage | +5% cooldown |
| Vitality | +5% maximum health | −3% movement speed |
| Guard | −4% incoming damage | −3% damage dealt |

**Co-op challenge unlocks:** a first technique can use `technique_requirements: {"duet_realm":"confluence"}`. The implemented challenge requires a successful Confluence Foundry co-op result with both Tide Keeper and Spark Keeper in the roster. Each player earns it for their own selected pair hero, saved in their downloadable profile as `duet_clear`. This is an explicit implemented challenge, not a general rule engine for arbitrary realm/team combinations. Teacher mode bypasses the requirement.

### Design the two techniques together

The first technique uses `ability` plus `multiply`/`set` to adjust existing stats. The final technique uses `ability` plus a **full `attack` object** to replace a different slot. Both are selectable; the base kit remains an option. Do not let them modify the same button.

A replacement can give up healing for damage, instant reach for charged precision, a close impact for a returning projectile, or manual detonation for timed bombs. Explain the loss as clearly as the benefit. Avoid “same attack but strictly stronger.”

**Chronicle Keeper example:**

| Choice | What changes | What it costs |
| --- | --- | --- |
| Base | Mark foes, rewind positions, capture bullets in a slowing field | Low direct damage; preparation and positioning matter |
| Restorative Rewind | Secondary heals 2 HP per rewound foe, capped at 6 | Secondary deals 25% less damage |
| Midnight Meridian | Special becomes an 80-damage piercing time ray with a charge and short stun | Loses bullet capture and area slow |

All four combinations are valid: base/base, first/base, base/final and first/final. Test all four, plus the passive and tuning. An alternate that removes a prerequisite must not silently break the remaining kit.

Use [Mastery Authoring Guide](MASTERY_AUTHORING_GUIDE.md) for a complete JSON example, [Mastery Catalogue](MASTERY_CATALOG.md) for titles/first techniques and [Final Mastery Catalogue](FINAL_MASTERY_CATALOG.md) for full replacements.

## 7. Artwork and animation

| Asset / phase | What students should show |
| --- | --- |
| Idle | A clear silhouette, consistent size and transparent background |
| Walk 1 / Walk 2 | Small pose changes; keep the feet/pivot and art detail consistent |
| Attack pose | The same character and art style, preparing or making its attack |
| Wind-up | Where and when damage will happen; ring, lane, tree tilt, glowing mark, etc. |
| Travel | A moving projectile, wave, chain or body; distinguish it from the impact |
| Impact | Brief burst at the actual hit location |
| Persistent field | Transparent enough to see the player; clear boundary and expiry |
| Passive / status | Small indicator or faint aura; avoid covering the character |
| Final alternate | Own effect art and understandable motion, not just a renamed skill |

Current character sprites are normally 64×64 PNGs: `<sprite>_idle.png`, `_walk1.png`, `_walk2.png`, `_attack.png`. Keep legacy `_0.png` and `_1.png` where a loader/example expects them. New art must share its scale, baseline and palette across poses. Effect SVGs work for the shared mastery renderer; use an `assets/` resource path for `visual_texture`.

Movement can be a separate visual system (basketball bounce, skating cadence, flight, teapot hops). Purely visual movement should not alter the ground collision point or accidentally increase average movement speed. New physical movement requires collision and multiplayer support.

Movement can also express identity without adding damage: Polarity has an idle hover, Spindle weaves gently left/right, Aurel leaves capped fading red footprints, and Snowdrift accelerates and coasts on ice at a reduced 180 top speed. These use `hero_motion_v85.gd` and the normal collision system. Molten Pilgrim’s lava patches deal 3 damage per second per owner; overlapping patches from one owner do not stack. Primary is 32 direct damage, secondary landing 22, with mild 1-per-second burns for 3 seconds.

### Lightweight hero movement cosmetics

`hero_motion_v85.gd` uses ground positions, a shared 96-trace limit, 1.6-second fading and off-screen culling. Cosmetics never damage, heal, slow or alter collision. `trace()` adds a fading ground/world mark; `landing()` emits Ripplejaw's puddle only after a completed flop. Live tracked heroes can draw tiny idle companions or steam without particle nodes. Disabled/dead and stale actor tracks are removed.

| Hero | Cosmetic |
| --- | --- |
| Wick-o'-Wisp | Tiny candle fireflies and rising amber trail sparks; separate from its gameplay aura |
| Molten Pilgrim | Fading red snail smudge |
| Clockwork Apiarist | One to three tiny bees orbit while moving or idle |
| Morrow Shepherd | Faint dark mist and trailing cloud wisps |
| Ripplejaw | Small puddle/ripple on a completed landing |
| Velvetwing | Falling purple wing sparks, including while hovering idle |
| Vesper | Silver-blue star/crescent trail |
| Sunpetal | Drifting yellow petals |
| Iris Chalkbinder | Tiny chalk cross marks |
| Tumblebrew | Rising steam and a faint steam trail |

Candle Light's combat aura/bonuses are enabled only in active gameplay, never in town or the multiplayer lobby. It must not be confused with cosmetic fireflies.

## 8. Items, food and enemies

A hero can carry **three items and one separate food piece**. Food is used automatically, once, when its condition is met. It is not a fourth manually activated item.

### Installed item effects

Copy an item in `content/items/`; `description` must explain the actual benefit. Items may be activated, equipped bonuses or conditional effects depending on their implementation.

| Effect id | Installed examples |
| --- | --- |
| `armor` | [Iron Bark](content/items/iron_bark.json) |
| `block_boost` | [Guard Buckler](content/items/guard_buckler.json) |
| `bonus_damage` | [Hammer Charm](content/items/hammer.json), [Crit Charm](content/items/crit_charm.json) |
| `bonus_health` | [Heart Locket](content/items/heart_locket.json) |
| `bonus_speed` | [Swift Laces](content/items/swift_laces.json), [Trail Boots](content/items/trail_boots.json) |
| `bounty` | [Bounty Magnet](content/items/gold_magnet.json) |
| `cooldown` | [Focus Lens](content/items/focus_lens.json) |
| `haste` | [Rush Tonic](content/items/rush_tonic.json), [Sprint Kit](content/items/sprint_kit.json) |
| `heal` | [Healing Potion](content/items/potion.json), [Field Medkit](content/items/medkit.json) |
| `invulnerable` | [Shield Draught](content/items/shield.json), [Aegis Capsule](content/items/aegis.json) |
| `lifesteal` | [Leech Charm](content/items/leech_charm.json), [Vampire Pin](content/items/vampire_pin.json) |
| `reflect` | [Mirror Shard](content/items/mirror_shard.json) |
| `revive` | [Last Stand](content/items/last_stand.json) |
| `shockwave` | [Frost Flask](content/items/frost_flask.json), [Ice Bomb](content/items/ice_bomb.json) |
| `thorns` | [Thorn Coat](content/items/thorn_coat.json) |

### Food choices

| Food | Automatic trigger and result |
| --- | --- |
| Berry Bun | Automatically eaten after damage leaves you alive at 60% health or less. Restores 30 HP. One use; cannot revive a fallen hero. |
| Hearty Stew | Automatically eaten after damage leaves you alive at 35% health or less. Restores 50 HP. One use; cannot prevent a lethal hit. |
| Antidote Pear | Automatically eaten when poison is applied. Removes poison immediately. One use. Does not remove slow, burn or bleed. |
| Cleansing Tea | Automatically drunk when poison, burn or bleed is applied. Removes all three effects currently on you. One use. Does not remove stun or slow. |

Food does not revive a dead hero. Healing food triggers below its configured HP threshold; cleansing food responds to the listed statuses. Slot, trigger, consumption and network ownership are handled in `provisions.gd`. Food/round completion healing must not inflate spell-healing statistics.

### Enemy choices

Enemies live in `content/enemies/`. Ordinary behaviours include close chasing, ranged shots, bursts, homing, dual ranged attacks, summoning and charging. Ranged enemies should keep distance and separate, not pile onto melee players.

| Design choice | Working place to look |
| --- | --- |
| Close enemy | Bramble / Rusher definitions and the normal movement/contact-damage loop |
| Ranged / weaving shot | Archer / Lantern Moth; projectile parameters and wall collision |
| Summoning plus direct attacks | Warlock; minion limits and its projectile attack |
| Lobbed exploding attack | Existing realm enemy custom controllers and `realm_trials.gd` lob system |
| Burrowing, resurrection, healing, nests or transformation | Moonburrow / Ebonwake controllers; copy the complete lifecycle, not only the JSON id |
| School boss or door sequence | `school_world.gd` and `content/schools/` |
| Multi-phase or multi-body boss | Neon Crucible / Shattered Oath controllers |
| Returning rival hero | `north_gate.gd`: target selection, ranged spacing, projectile dodge, cooldowns, kill XP, persistent match levels, timed respawn |
| Delayed siege patterns | Tollbreaker: warning rings, explosive projectile volleys and radial release; host resolves damage, guests receive warning snapshots |
| Marching lane soldiers and shared bounty | North Gate routes, outpost/base batches, formation spacing and fractional per-player rewards |

A `custom_attack` id is a hook into a particular world controller; it is not a universal hero style. New enemy mechanics need warnings, contact/ranged damage, limits, defeat rewards, correct room-clear behaviour and host snapshots. The Last Bus, for example, alternates charge, passengers and a growing Horn ring that stuns once for 1.5s.

## 9. Build and test checklist

1. Copy a working hero with the closest **mechanic**, rename its id/file/sprite, then add it to the manifest once.
2. Make all four consistent poses and matching ability effects. Check selection art as well as in-world art.
3. Test primary at level 1, secondary at 3, passive at 5 and special at 6. Check level-up descriptions on a phone-sized viewport.
4. Use the training yard: grouped dummies, moving dummy and projectile shooters. Test walls, range edges, empty targets and repeated hits.
5. Test the base kit and all combinations of the two mastery techniques. Keep their buttons different; verify descriptions, crits and tuning.
6. Test solo and host/guest co-op, plus PvP team rules. Only the host applies combat damage; guests draw snapshots. Healing never targets rivals.
7. Check that summons, mirrors, mines and captured shots expire and stay capped. A dead/removed target must not leave a permanent effect.
8. Check food, death/respawn, mastery recording, profile export/import and reload. The chosen hero should survive a return to town.
9. Run Godot’s import/parse check and relevant tests before packaging. Some older `tools/content_manager.py` limits predate specialised kits; it is not the complete authority for modern custom attacks.
10. Update this catalogue when adding a **new selectable mechanic**, its authoring guide when the schema changes, and the mastery catalogues when adding a hero. Keep release notes in `UPDATE_*.md`, not here.

For a genuinely new mechanic, follow a small combat module like `chronicle_combat.gd`: `cast`, host-only `step`, `reset`, `snapshot`, `receive` and `draw_on`. Register it with `object_combat.gd`. A new style must work in the main realms and multiplayer modes; a new JSON label by itself is not an implementation.



## Shared combat feedback (v76)

Use `scripts/combat_cues.gd` for preparing enemy circle, corridor and rectangle attacks. Warnings use an outlined shape, amber `!` and a progress arc where appropriate; damaging impacts should have a distinct effect. Green `+` marks a healing area. Status icons use shape and colour: orange flame for burn, red drop for bleed, blue downward chevrons for slow, white rotating star for stun and purple dots for poison. `presentation.sound_for(style)` selects a bounded audio cue; the top-right Sound button mutes all audio. Keep tutorial practice rewards separate from real progression.

## Playstyle tuning (v77)
Mastery sliders are signed −2…+2. Each step away from neutral uses one point (four equipped maximum). Power exchanges damage and cooldown, Vitality exchanges health and movement, Guard exchanges defence and attack. These are global balanced multipliers, not additional ability slots. Design both mastery techniques so either slider direction remains playable. Arena hosts can start everyone at level 10; all core abilities must work without an earlier leveling sequence.

Windlass Swing uses `duration` (default 2.2 seconds), with one contact hit per enemy per swing. Nullweaver target placement uses cursor distance, capped by range and walls; mobile uses the aim stick at maximum range.

## Sixty-hero release patterns

- **Bouncing lob:** visible vertical arc with ground-contact bursts and a per-projectile hit list. Briar can redirect and enlarge its own airborne projectile without clearing the hit list.
- **Collision-aware leap:** authoritative timed travel with a visible arc, safe endpoint and sparse network corrections. It is not automatically invulnerable.
- **Friendly service field:** aimed healing/cleansing mat, one cleanse per visitor, timed healing ticks and a duration cap. Use team checks so rival players cannot receive its benefits.
- **Moving interception front:** advancing cone line with one hit per foe and a finite hostile-projectile interception budget.
- **Health expenditure / debt:** pay health without reaching zero; store a capped resource; spend it on an ability. Spending does not count as enemy damage or healing.
- **Held pull-and-release:** periodic damage and brief refreshed attack suppression inside a pull area; slowed caster movement; captured projectile visuals; release knockback; automatic duration fail-safe. Replicate held-input state and support touch release.
- **Paired-door teleport:** visible departure and destination, brief transit delay, collision-tested landing and capped healing/protection. An alternative can return to the original safe location after a delay.

Character data, mastery alternatives and hero-library metadata are separate responsibilities. Every new attack style needs authoritative implementation, visuals, multiplayer state, balanced caps and a student-friendly explanation. Refer to HERO_LIBRARY_GUIDE.md for browsing metadata and future additions.

## Opposed rotating beam technique

Owl Eyes shows two opposite energy beams from the same caster. Both follow aim for two seconds, use wall visibility checks and one shared damage tick per foe (so overlap near the caster cannot double damage). Replicate beam direction, remaining duration and tick state. This example replaces a healing secondary rather than adding free power on top of it.

## Team projectiles and companion formations

These styles live in `scripts/party_heroes.gd`, invoked through ObjectCombat's normal authoritative dispatcher. Use the existing ability schema, and give every new style an aimed/travel/impact/status cue. Guest casts send the same attack request; the host determines hits.

| Type | Styles / example | Authoring requirements |
|---|---|---|
| Enemy damage / ally healing projectile | `kindred_dart`, `heavy_kindred`, `kindred_fan` | First target only; skip caster; check friendship before choosing damage or healing. Healing at full health still absorbs the shot. Fan pellets use lower values. |
| Timed healing / protective area | `lumen_relay`, `rescue_buoy` | Set radius, duration, tick interval, healing and damage reduction. No accidental free full heal or double tick. |
| Cleansing / projectile-catching area | `lumen_sanctuary`, `hush_buoy`, `safe_passage` | Check hostile ownership, impose a catch budget and show the boundary. Do not catch teammates' shots. |
| Weighted merging summons | `mosaic_seed`, `mosaic_scatter`, `mosaic_guardian` | Capacity counts original pieces, not bodies. Sum actual HP, cap max HP by weight, refresh lifetime only when joining and require quiet proximity before automatic merge. |
| Summon ward / marching sacrifice | `mosaic_ward`, `mosaic_parade` | A ward expires. Marching units burst and are consumed. Splitting cannot heal or duplicate capacity. |
| Ranged companions and coordinated volley | `hive_lantern`, `swarm_relay` | Set cap, HP, lifetime, movement, attack interval and projectile reach. Regrouping must not silently reset health or lifetime. |
| Sideways or inward control field | `traffic_order`, `inward_order`, `honey_court` | Radius/duration/slow are explicit. Movement respects valid terrain. Pull is a selectable trade-off, not bonus power. |
| Delayed area stun | `quiet_court` | Warning before impact; use `stun_duration` in the status payload. |
| Slowing melee / paired shots | `harbor_note`, `harbor_mend`, `apiary_crook`, `bailiff_thread`, `twin_threads` | Specify shared or per-hit cooldown, damage, status duration and visual footprint. A healing replacement gives up damage. |

A companion may be melee or ranged and can carry per-unit speed, damage, interval, reach, rally target and weight. Reuse normal actor collision, health/status and snapshot paths; exclude summons from XP farming. Clean up when the owner dies. New module budgets: 96 projectiles, 32 fields, 64 flashes. Avoid adding uncapped effects on every frame.

## Stance and pack additions (v89)

A hero can have timed primary/secondary variants. Author normal, ranged and temporary special forms, an expiry rule, visible timer and authoritative state. Tempo Monk uses twelve-second natural alternation and a bounded special override. Its first mastery changes primary timing/damage; its final mastery replaces the special form, so the two changes do not conflict.

Available styles: monk_primary, monk_secondary, monk_special, monk_shadow, quill_claw, quill_lunge, quill_stampede, quill_summon and quill_pack. Travelling melee attacks clip against collision, prevent competing movement and hit each target once. Temporary immunity and damage reduction must have expiry and feedback. Quill companions have a maximum count, finite life and HP; rallying does not reset old units. Replacement mastery attacks use the technique attack dictionary before stat tuning.

Grounded darts need finite lifetime, fading and single-consumption contact rules; Lumen uses 1.5 seconds. Damage reduction displays a percentage and grey pulse. Art must include all four standard poses, portraits and companion poses where used. Stable public hero numbers live in content/hero_numbers.json, separate from roster order.

## Realm encounter portraits for new content

Register enemy ids in the manifest and in your realm/campaign spawn definitions. Run `python3 tools/build_encounter_rosters.py` after changing a realm's enemy list. Its output is `content/encounter_rosters.json`. Script-generated enemy sets may need a mapping entry in that generator. Portraits use the enemy sprite prefix. Discovery records are per-realm in portable legacy profile data; do not mark them revealed simply because a realm was selected.

### Defeat interception and revival passives

`ash_rebirth` is implemented by scripts/v90_heroes.gd and connected to lethal damage in both game.gd and arcade.gd. Its pending state blocks movement/attacks, prevents premature party defeat and ordinary arena respawn, and is included in host snapshots. Revival restores 50% maximum health after 3 seconds, with a 120-second active-combat cooldown. Preserve that cooldown when resetting floor combat effects. Do not implement revival as a normal heal: a dead hero is not an eligible ordinary healing target. Keep defeat/KO statistics accurate even when a hero revives.

`v91_scissors` shows a warning at the aimed crossing before its close area hit. `v91_pistol` uses the existing finite travelling projectile controller; its round stops on collision and its impact invokes the tied-target passive. Copy the updated Merrymask / Dust Marshal JSON examples for these styles.

## Battlegrounds army targets

Hero abilities can target opposing soldiers and base structures in Battlegrounds, while support effects respect team allegiance. Structures are immune to status effects and cannot be converted. Barracks protect their heart until every opposing barracks is destroyed. Army soldiers can be slowed, stunned, burned, poisoned and knocked back. Corpse raising and temporary enemy conversion work on soldiers. Troops are match actors, not additional realm encounters or profile unlocks. See **BATTLEGROUNDS_GUIDE.md** for unit roles and authoring boundaries.

## Charge-and-release weather attacks

| Style | What the student designs | Important settings |
| --- | --- | --- |
| `twister_charge` | Hold primary to grow a visible funnel; release to launch it. Funnels curve slowly, damage on timed contact and slow foes. Full charge adds strong pull. | `damage` is damage per 0.5-second tick at minimum charge; full charge multiplies it by 2.4. `radius` grows up to 1.7 times its base; `max_funnels` defaults to 4. Charge caps at 1.6 seconds. Duration is 4.2 seconds. |
| `twister_stride` | Transform into a steerable tornado that damages and slows nearby foes. | `damage` per 0.5-second tick; `duration` (3 seconds); 48 contact radius and 1.2 movement multiplier, with gentle weaving. Swallows nearby hostile projectiles; this grants no immunity to melee or area attacks. |
| `twister_hail` | Immobilised channel, followed by randomly scattered, warned hail impacts. | `charge_time` (2 seconds), `damage` per landing; 12 landings, 38 impact radius, 0.7-second warnings, 0.6-second stun. |
| `twister_sleet` | Alternative special: directed corridor of ice, using the aim at cast time. | `charge_time` (1 second), `damage` per landing; slow 45% for 3 seconds, with no stun. |

Reference hero: `content/characters/twisterspell.json`. Controller: `scripts/twister_combat.gd`. Timed contact damage, expiry, obstacle clipping, friendly protection and the per-owner funnel cap are mandatory. Charge state travels in host snapshots; primary hold/release uses the existing input transport. The passive `weather_circuit` connects three or more owned funnels within 260 reach with lightning every 1.25s: crossing foes take 8 damage and 0.35s stun. Full-charge funnels can also zap a foe within radius + 90 for 10 damage every 1.5s. Shocks are limited to once per target per caster per second. Link effects expire after 0.28s and are bounded; walls block them.

## Mounted melee, flight, afterimages and health trades

These are reusable implemented styles in `halloween_combat.gd` and `v110_combat.gd`. Copy the linked character file as a complete example. Every hit checks teams and walls; damage and effect state belong to the host. Effect arrays are bounded and cleared on entering town.

| Style | Behaviour | Supported configuration / trade-off | Example |
|---|---|---|---|
| `grave_cleave` | Forward scythe sweep with a 0.12s wind-up and matching blade reach | `damage`, `range`; mounted primary gains 6 damage | Hollow Rider |
| `grave_toll` | Lantern slam releases a spectral radial shockwave after 0.3s | `damage`, `range`; 55 knockback, 1.2s stun; successful hit triggers passive guard | Hollow Rider |
| `grave_ride` | Controllable spectral mount for 5s | 30% faster movement, contact `damage` every 0.75s within 52 reach; no immunity | Hollow Rider |
| `grave_guardian` | Targetable stationary spectral horse | 70 HP, 6s lifetime, 14 melee damage; replaces mounted mobility | Hollow Rider final mastery |
| `witch_chain` | Spinning fireball; direct enemy hit damages and slows, missed/wall hit creates a pool | `damage`, `range`, optional `frost`; 4s, 43-radius ground pool; max 10 per caster | Hazel Hex |
| `witch_flight` | Fly toward the selected safe destination, dropping warned bombs | `range`, `damage`; speed 560, up to six bombs, 0.45s stun, 2 burn damage/sec for 3s; passive adds 1s burn | Hazel Hex |
| `witch_brew` | 7s cauldron fires a splatter at every visible foe in range once per second and buffs nearby allies | 240 cast reach, 310 attack reach, 150 aura; `gentle:true` replaces attacks with healing | Hazel Hex |
| `echo_cut` | Direct forward cut repeats from the same position after 0.45s | `damage`, `range`, `echo_ratio`; remembers last three strike origins for 5s | Echo Dancer |
| `echo_feint` | Return to last remembered strike origin; damage at departure | Max 400 clear-route teleport, 70-radius departure burst | Echo Dancer |
| `echo_encore` | Replay up to three remembered cuts in order | `damage`; 105 reach, 0.3s spacing; requires `echo_cut` memories | Echo Dancer |
| `echo_company` | Summon a fragile melee companion at each remembered origin | Max three, 24 HP each, 6 damage, 6s duration; requires memories | Echo Dancer final mastery |
| `mini_jabs` | Three forward punches; same target hit three times receives slow | `damage` per punch, `range`; 0.1s spacing, 35% slow for 2s | Little Menace |
| `mini_shift` | Half-size hero with a smaller direct projectile target; can still attack | `duration`, `move_factor`; no immunity, no contact damage, AoE still hits | Little Menace |
| `heart_forfeit` | Charge for 1s at reduced speed, then pay maximum-health fraction; damage foes around caster by that amount before their defences | `health_cost` (0.5 or 0.75), `range`; cost bypasses protection and can defeat caster | Little Menace |

Cauldron auras grant **5% damage and 8% life-on-hit**, capped at **6 healed HP per hero per second**. Multiple cauldrons do not stack. Damage-over-time and self-sacrifice do not produce aura healing. Cauldron poison deals 2 damage per second; pools also slow by 30%. Flight destinations are clipped to clear, legal routes so a broom cannot skip a locked progression door. Bombs and splatters have visible landing warnings.

`heart_forfeit` does not credit self-damage as damage dealt or award a hero kill for self-defeat. Practice mode keeps the caster at 1 HP; real runs and arena matches can defeat the caster. The 75% mastery choice reduces radius to 110 from 165, rather than being a free damage upgrade.

Additional implemented passives: `lantern_courage` (successful hook: 12% defence for 2s), `ember_infusion` (broom bomb burns last 1s longer), `echo_applause` (primary echo repeats 65% rather than 50% direct damage), and `small_courage` (three jabs hit: 10% defence for 1.5s). Their beneficial indicators use the existing damage-reduction UI.

The Training Yard includes a green allied target with its own 200 HP pool. Healing projectiles, nearby healing fields and ally buffs can target it. It starts injured; press E nearby to reset its health and buffs, or wait three seconds after healing it fully. Practice never grants mastery or profile rewards.

## Earthquake fields and allied weapon enchantments

Controller: `scripts/v112_combat.gd`. These abilities use team checks and line of sight, expire automatically and clear in town.

| Style | Behaviour | Settings and trade-off | Example |
|---|---|---|---|
| `ram_quake` | Fixed, shaking circular field; six damage pulses across three seconds; enemies inside slow 65% | `damage` is the **total**, divided across pulses; `radius` defines the matching damage and visual boundary. Leaving avoids later pulses. | Young Ram |
| `hearth_tap` | Forward melee lantern sweep | `damage`, `range`; one hit per enemy per cast | Hearth Herald |
| `hearth_kindle` | Five-second buff to self and allies within 220 at cast time | +8% attack damage; direct hits apply 2 burn damage/sec for 3s, once per target per attacker per second. Same enchantments never stack. | Hearth Herald |
| `hearth_march` | Alternative enchantment; retains damage bonus, replaces burn with life-on-hit | Direct hits heal attacker for 3 HP, at most once per target per attacker per second; DoT cannot trigger it | Hearth Herald first mastery |
| `hearth_beacon` | Placed banner heals allies for six seconds and intercepts hostile projectiles | 280 cast reach; 180 radius; 4 HP/sec; up to six intercepted projectiles; friendly shots pass through | Hearth Herald |
| `hearth_mend` | Alternative banner trades projectile catching for healing | 7 HP/sec; six-second lifetime; same range and radius; no catching | Hearth Herald final mastery |

Passive `shared_hearth`: allies within 170 reach gain 10% damage reduction; multiple copies do not stack. Existing DR display shows this protection. Allies must stay near the owner, and walls block the aura. Weapon buffs apply only to allies and do not recursively proc from burn or other damage-over-time.

Stealth visibility is separate from invulnerability. In PvP the hidden enemy hero, attached effects, status markers, nameplate, health bar and minimap marker disappear. The owner and allies retain a faint silhouette, and broadcast spectators retain visibility. Area attacks can still hit invisible heroes.


## Daily challenge content

`content/daily_challenges.json` contains 50 authored tasks. Each has a unique `id`, a readable `title` and `description`, and a `kind` of `realm`, `descent` or `defense`. `team` selects `solo`, `party` (at least two human players) or `any`. Realm tasks choose a realm ID (or `*` for any realm) and optionally a hero ID. Survival tasks specify a cleared floor/wave `target`, never merely a spawned wave.

The local-calendar shuffle gives one shared task per day, without repeats within a 50-day cycle. Normal realm victories and confirmed survival clears report completion; tutorial, training, spectators and Game Dev play do not count. Completion lives in the portable profile. The Daystar Crest is a cosmetic animation until local midnight; it changes no damage, healing, movement or defence. Add new tasks by authoring content and reviewing the calendar's 50-task contract and regression checks together.

### Held lanterns, charged scythes and echo waves
- `hearth_light`: held primary channel; a wall-blocked forward light cone damages enemies and heals allies/self. Uses `held_channel` plus `hold_charge` for multiplayer press/hold/release input.
- `grave_cleave` with `hold_charge`: charged scythe sweep; full charge applies bleed.
- `apiary_needle` with `hold_charge`: charged amber projectile; full charge applies stun.
- `whistle_wave`: advancing broad sound front; hits each enemy once, pierces foes, stops at walls.

### Directed companions and charged area projectiles
- `mosaic_seed`: summon a living tile and mark a clicked hostile actor. Existing tiles prioritize the mark. Capacity remains bounded: five guardian pieces plus two single companions.
- `mosaic_scatter`: split pieces, rally and temporarily increase movement/attack speed.
- `mosaic_bubbles`: charged five-projectile fan; bubbles pop on foes/walls/range and leave temporary slowing splashes.
- `oar_sweep`: animated melee sweep with one hit per target; hold-charge increases damage and applies slow at full charge.
- `patch_buddies`: targetable separated companion pair, with passive/mastery duration support.
- Full-charge Stormscribe `ball_lightning`: bounded periodic nearby shock damage during projectile travel.


## Portable ability audio

In Ability Lab → Sound, attach a WAV/MP3 effect (≤4 seconds, ≤128 KB), or select an example. Set level (−36 to −6 dB) and pitch/playback speed (0.5×–2×). It plays on cast/release in lab and solo custom-hero tests, obeys the global mute and travels inside ability/hero/profile exports. Damage ticks do not replay it. Fade edges, trim silence and balance against other effects. Level 3 shows the actual audio code. Realm music is a separate teacher-curated asset submission.
