# Crossroads: Realms Beyond — v176 private preview

**Matching client/server: V176-preview, protocol 10.** This package is ready for private testing. It has not been deployed to Render or published on itch.io. Keep a backup of the current game and exported profiles.

## Town and interface

The courtyard Starlace Elder has a new layered vector canopy, leaf sprays, weathered branches and roots. Existing night twinkles remain. The Studio now sits between its former two positions, with its artwork, collision, doorstep, resident destination, street connections and lanterns moved together. Its western approach avoids the cottage.

The Saturday Makers' Fair and its residents now gather south of the heritage tree. The travelling fruit/bait stall is also clear of the new bread cart and nearby building roofs. The free-bread display is now the **Hearth & Crumb** cart beside the Food Stand, with striped canopy, wheels, signboard and scored loaves. Existing bakery rewards and project requirements remain; Interact at the cart opens the town provision options.

Cloudy and Rain weather now cast large, slowly passing shadows over the world. These use a small fixed number of native shapes and leave the HUD clear. Existing rain, puddles, mist and real 24-hour Edmonton day/night timing remain.

The central town portal has moving inner energy, orbiting motes and a luminous ring. The Adventures **Realms** option opens **Portal Expeditions** directly. Shared objective placement now accounts for combat headers in solo and co-op, including school, immersive, quest and technology realms and the Between/Overcharge panels. Co-op status and food text no longer share the realm objective's row.

## School realms

Firstbell Elementary, Crossbell Middle School and Crossroads High have substantially narrower main halls: about 384–420 world units instead of 750–950. The map transformation moves connected floors, doors, stairs, encounters, props, merchants, quest objects and triggers together. Room identities and objective sequences are retained. The navigation grids are rebaked.

Middle School adds seven patrol enemies across the arrival, library, lab, gym and roof groups. Extra melee sentinels and paper-spirit volley variants increase pressure. Volley patrols fire eight slow projectiles outward, with a longer recovery between bursts. Difficulty and human clear times still need student playtesting.

## The Between: portal strength

New solo expeditions freeze their unlocked reach when the run starts. In co-op, **the host's profile selects the reach for both players**; a more advanced guest does not enlarge a less advanced host's expedition. Both players still need the normal Between entry unlock.

| Realm progress | Maximum danger ring | Normal biome additions |
| --- | ---: | --- |
| Between unlocked by Sunfield or Frostbound clear | 6 | Grove, Quarry, Frostbound |
| Clear 3 different medium realms | 8 | Silverfall |
| Clear 1 challenging realm | 10 | Lantern Marsh |
| Clear 4 different hard realms | 12 | Astral |
| Clear 2 different expert realms | 14 | Deepest outer fractures |

The portal menu shows the current reach and next requirement. Locked outer crossings are physically blocked. Seeded modules stay connected and normal generation uses only the unlocked biome set. Streamed neighbourhood and active-enemy limits remain bounded; a larger total map does not load the entire world at once.

The solo level-10 Attunement Challenge remains reachable in the base map: all six Crossing Seals lie in rings 3–5. Its six Warden arenas are special biome pockets, separate from normal biome unlocks. Attunement still unlocks overcharge and relic eligibility. Existing earned attunement and relics are retained.

Older solo tickets retain their saved layout and original ring-12 reach. Fresh runs use the new progression rules. Existing downloaded profiles remain the persistence system; this does not add online accounts. Numeric fields are checked through real JSON export/import, including expedition reach, co-op reservations and Conclave actor identities.

## Five overcharged realms and four new relics

The daily rotation now includes **Honeyglass Gardens** and **Sunfield Expanse**, alongside Grove, Quarry and Frostbound. Only the featured realm is available to overcharge that day. Its ordinary unlock still applies. Every attempt costs 100 / 200 / 300 shards; normal boss relic chances and pity are unchanged.

| Realm | Relic | Main effect |
| --- | --- | --- |
| Honeyglass | Mellifera's Nectar Vial | Healing food restores an extra 3–5 HP, with an 8s cooldown. |
| Honeyglass | Prismatic Honeycomb | After a dodge, the next hit within 4s deals 6–9% extra damage; 8s cooldown. |
| Sunfield | Solstice Sunseed | A kill grants a 4–6 HP shield for 4s; 10s cooldown. Shields do not add together. |
| Sunfield | Sunward Brooch | Above 80% health, incoming damage is reduced by 4–6%. |

All four work in solo and dedicated co-op. Effects belong to their wearer; existing two-slot restrictions and supporting-stat caps remain. Relics stay disabled by competition rules. No relic is guaranteed on every realm completion.

## Rare encounter: the Waylight Conclave

Each overcharge attempt has a **12% seeded chance** to contain one roaming pack of four champions: Aegis (tank), Cantor (healer), Ravager (melee) and Prism Seer (ranged). They have distinct role cues and much higher health than regular foes. The healer restores nearby allies; the Seer telegraphs an eight-way volley. Melee strikes also warn before damage. The pack patrols when players are distant and engages nearby players, respecting stun, slow and stealth. The encounter adds at most four actors, uses bounded warnings/projectiles and does not respawn farmable champions.

Defeating all four secures a **Conclave Cache**. Finish the realm and use its exit to bank **+3 Waydust** plus a separate **35% chance** at a **Conclave-forged relic**, starting at rank 1. It uses the current realm's family and displays its special provenance in Inventory. This roll is independent of the ordinary boss roll and does not consume or advance ordinary pity. A full relic collection converts a successful bonus drop to Waydust.

The cache is not awarded on defeat or abandonment. Saved solo runs retain encounter state; co-op replicates it from the authority. Each participant receives a personal bonus roll. Duplicate settlement cannot award another cache. Encounter placement waits for authored realm enemies to initialize, including the new immersive overcharge realms.

## Install and verify

1. For local Godot debug play, extract **Crossroads_v176_Editable.zip** and open the enclosed `project.godot` in Godot 4.5.1 / the matching 4.5 series.
2. For Render, replace the complete server repository contents using **Crossroads_v176_Server.zip**. Preserve the root Dockerfile and folder structure. Keep the existing database, service endpoint, environment settings and report credentials; no database rename or account migration is needed.
3. Redeploy, then check `/health`: `ready: true`, `build: V176-preview`, `protocol: 10`.
4. Upload **Crossroads_v176_Web.zip** to the private HTML test page. Its `index.html` sits at ZIP root. Refresh browser clients after the matching server is ready. Earlier clients deliberately cannot connect to protocol 10.

## Validation and next human test

Native checks cover all three school objective sequences and co-op door/stair replication; updated navigation caches; portal-reach milestones and blocked boundaries; host-selected reach; all five overcharge families; the four relic hooks; Conclave spawning, healing, telegraphed projectiles, actual defeats, checkpoints, personal bonus rewards and duplicate settlement. Portable state is checked through JSON, including champion IDs and expedition reach.

Combat, owner projectiles, 480 movement comparisons, T4 reconciliation, food, ordered interactions, profile rewards, profile import and 5,250 fishing mastery checks are retained in the regression suite. Real WebSocket client/server checks exercise consent, personal entry fees, host reach, movement and reconnects. Packed web checks cover desktop and phone-sized layouts, town changes, the three school halls and the elite encounter. The final archives are checked for integrity and the extracted server is imported and started separately.

These checks do not establish Chromebook FPS, eight-player school-network smoothness, or human difficulty/economy balance. For the next playtest: complete Middle School, compare a less advanced and more advanced host's Between reach, then play Honeyglass/Sunfield overcharge. Check the fair and fruit stall at their actual weekday/time, the town portal at night, and moving shadows during Cloudy weather. Report any persistent graphics context loss separately.
