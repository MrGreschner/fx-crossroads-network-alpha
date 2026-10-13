# v159 — Fishing waters & Ripple and Reel

## Start fishing

Walk to **Ripple & Reel**, the new aquarium and tackle shop on the southeast riverbank, south of the Training Yard. Its doorway opens a small walkable interior. Talk to **Marina** and choose **Discover my fishing rod**. The rod is a permanent local-profile unlock; it needs no combat item slot and does not change hero abilities.

Find bubbling water and stand at the shore marker. Press **F**, or the on-screen **Cast** button. Wait 6–12 seconds for the float to dip, then press **F / Hook** within the 3.8-second gold bite window. Missing it loses the bite; moving, taking damage, opening another menu, dying or changing maps cancels the cast. **Combat continues during realm and multiplayer fishing.** Existing summons and opponents continue acting.

Choose **Keep catch** or **Release**. Both record the species and its best size in normal play. Species rarity and catch weight are separate: a common species can produce a trophy-sized specimen. Super-rare catches remain genuinely rare; there is no guaranteed legendary reward.

## Waters

| Location | Fishing holes | Species per hole |
| --- | ---: | --- |
| Town pond | 1 | 8: 3 common, 2 uncommon, 2 rare, 1 legendary |
| Town river, immediately south of the east bridge | 1 | 16, across five rarity tiers |
| Wayfarer quest river | 3 | 3 / 6 / 9 |
| Silverfall Reach | 2 | 4 including 1 legendary; 9 including 2 legendary |
| Folded Coast | 1 | 8 |
| Lantern Marsh | 1 | 5 |
| Ram Descent, floor 56 only | 1 | 5 |

There are **32 distinct illustrated species** across the waters; appropriate species are shared between connected habitats. Each has its own original SVG illustration, colour, shape, markings, rarity and weight range. Visible fishing holes bubble continuously and show a small fish jumping roughly every 45 seconds. Invisible/offscreen holes add no fish draw calls.

Town banks have small wooden fishing platforms. The quest banks reserve clear space during scenery generation. Realm banks use existing walkable shore geometry. Floor 56 searches the generated floor for a clear bank; no spring appears on other floors. Fishing is unavailable in tutorial, training, arena, battlegrounds, defence and other unsupported areas.

## Your collection

- Keep up to **100 specimens**, with species, weight, length, trophy size, water and catch date.
- The shop has **five animated display tanks**. Use Catches & display tanks to put a kept fish into Tank 1–5; the same specimen cannot occupy two tanks.
- Choose **Feature on player card** to display a favourite's illustration, weight, length and rarity below the existing profile badges.
- Releasing a kept fish clears any tank and favourite using it, but retains the discovery and best-size record. Releasing a kept specimen requires confirmation.
- The journal conceals undiscovered species. Kept catches are paginated ten per page, with touch-drag scrolling for mobile.
- Your fishing unlock, discoveries, kept fish, displays and favourite travel with **Download Profile / Upload Profile**. Old profiles without fishing data receive an empty collection.
- Practice Continue and Playtest catches do not award collection progress. Game Dev gets the rod automatically and can try temporary catches and tank displays; its normal profile saves remain protected.

The shop is also accessible from Adventures → Build, trade & create → Fishing & aquarium. Elder Ram explains how to fish and where to find the waters. Shop and journal interfaces retain readable labels and mobile controls.

## Patrol and rendering fixes

Mistglass Spire's guard route no longer begins inside the tower. The east patrol goes around its collider and visible artwork before crossing the bridge, leaving room for both guards. Ripple & Reel has a connected approach path, a reserved building lot and a clear doorway. Town world rendering is hidden while its opaque interior is open. Fishing art is cached, bubbles are simple culled draw commands, and no physics bodies or particle nodes are created for every ripple.

## Checks

- Godot 4.5.1 import/parser validation.
- Solo fishing lifecycle, missed bites, movement/damage interruption, keep/release, five-tank uniqueness, favourite cleanup, bounded save validation and complete profile export.
- Reachable banks in town, all three quest holes, both Silverfall pools, Folded Coast and Lantern Marsh.
- Co-op host/guest fishing logic, attack suppression while casting, death interruption, and floor-56 spring placement. These are local controller checks, not a two-school-device network soak test.
- Guard collider and sprite clearance along the revised Spire route.
- Native Godot visual inspection of the shop exterior, aquarium, keeper dialogue, journal, catch panel, town banks and profile favourite.
- Existing hero-grid regression and room-service suite (70 checks).

This is an editable source project. Export Web/Windows before uploading or distributing; see DEPLOY_V159.md.
