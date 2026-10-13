# v152 — the realm journey

## Realm unlocks

| Starting point / achievement | Opens |
| --- | --- |
| New profile | Whispering Grove and Ember Quarry |
| Beat either starter | Honeyglass Gardens and Firstbell Elementary |
| Beat either of those two | Sunfield Expanse and Frostbound Rink |
| Beat either moderate introduction | All medium realms |
| Beat 3 different medium realms | Challenging realms |
| Beat 1 challenging realm | Hard realms |
| Beat 4 different hard realms | Expert realms |
| Beat 2 different expert realms | Extreme realms |

Repeated clears do not count as different realms. Practice continuation cannot earn clear credit. Earlier legitimate clears remain recognised. Playtest and GameDev bypass the gates. Locked entries explain what to do next. The tutorial results include **Start first adventure • Whispering Grove**, alongside retry and town choices.

## Maps

- **Whispering Grove:** shorter, continuous woodland trail; a calm arrival; spaced introductory encounters; a wider boss clearing; reduced first-adventure enemy count and boss health.
- **Ember Quarry:** a connected industrial trail with mine rails, cooled ground and distinct encounter stretches. Its split guardian remains. Arrival and enemy placement are gentler than the old opening.
- **Sunfield Expanse:** golden meadow details and sunflowers; intentional canopy ambush pockets; trees cleared from the route. Dense animated grass has been removed. Early melee pressure develops into mixed encounters and Saffron Hopper ambushes.
- **Frostbound Rink:** packed-snow route and rink markings; safe practice snow first; later mixed enemies and fractured ice. Blue cracked patches retain the direction you enter them, allowing only limited steering until you reach snow. Stuns stop ice momentum; collision rules still apply.
- **Petalbrook Canopy:** rounded, wider connectors, clearer bridges and trails, softer garden details and canopy placement. New patrols stay outside the closed guardian seal so progression cannot deadlock.

## New enemies

| Realm | Enemy | Style |
| --- | --- | --- |
| Sunfield | Saffron Hopper | Fast grasshopper with a warned dash |
| Petalbrook | Silk Spinner | Spider firing a slowing silk spread |
| Petalbrook | Dewcap Guard | Mushroom guard with a warned spore stomp |
| Brasslock | Brass Sapper | Mole mechanic planting delayed blasts |
| Brasslock | Keywing Courier | Fast flying clockwork bird firing returning keys |

Each has editable idle, two walking and attack SVG poses, registered portraits and combat behaviour. They remain specific to authored realms rather than silently entering random Descent pools.

## Bosses and rendering

Trial guardians now advance and strafe, including all four Shattered Oath guardians. Other bosses retain their existing attack controllers; an authority-only movement fallback helps a nearby boss that has stalled. Stunned and deliberately buried/down bosses remain stationary as intended. Sunfield’s ranged guardian now repositions instead of simply holding its distance.

Cached small scenery graphics and coarser immersive-floor texture sampling reduce repeated drawing. These changes were checked locally; they are not a measurement of FPS on school computers.

Read DEPLOY_V152.md before publishing. This ZIP contains editable source, not the exported browser game.
