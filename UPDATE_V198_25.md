# Crossroads: Realms Beyond — v198.25 • Changing Tides

Build: `V198.25-changing-tides`. Full release based on v198.24, preserving the aquarium income system and all prior work.

## Five new bait choices

| Bait | Fishing level | Buy price (three uses) | Craft batch | Target interactions |
|---|---:|---:|---|---|
| Honeygrain Paste | 5 | 15 Glimmers | 2 Sunleaf + 1 Ember Petal | River Sprat, Russet River Chub, Olive Lake Perch |
| Moonmoth Lure | 10 | 24 Glimmers | 2 Glowwing Insects + 1 Mooncap | Midnight Glassfin, Violet Lake Eel, Bluebar Trout |
| Saltflash Strips | 12 | 27 Glimmers | 1 River Mint + 2 Ember Petals | Ocean only: Copperback Mackerel, Squallfin Marlin, Pelagic Monarch |
| Kelp Crumble | 8 | 21 Glimmers | 2 Sunleaf + 1 Willow Bark | Ocean only: Blue Spiny Lobster, Copper Reef Lobster, Crown Reef Crab |
| Fish Roe | 10 | 18 Glimmers | 1 River Mint + 1 ordinary kept Common/Uncommon rod fish | Cages/baskets only: ocean lobsters/crabs and freshwater crayfish |

Crafting makes six uses before existing mastery bonuses. Buy/craft/equip through the Angler’s Workshop. All new stocks start at zero; existing bait is preserved. Nine stocked baits plus the unlimited bare hook are supported in profile validation.

Favoured species receive **3× relative catch weight** from their matching new bait. This is not triple final probability or a guaranteed catch. Time, weather, equipment and mandatory-bait requirements still apply. Oldwater Crownback still requires Scented Worms AND rain. Saltflash and Kelp Crumble cannot be used in freshwater, including the Night Island crater lake. Fish Roe cannot be used with rods or nets.

Roe crafting consumes only an eligible Common/Uncommon rod species already in the kept collection. Trophies (checked by actual weight), player-card favourites and displayed specimens are protected. Unbanked voyage cargo is never an ingredient. Fish Roe is also available to buy, so crafting is optional.

New bait illustrations appear in the workshop; discovered fish guide entries show favoured baits.

## More ocean cage creatures

Four new species have distinct native SVG artwork, separate silhouettes and aquarium geometry:

| Species | Rarity | Ocean habitat | Method |
|---|---|---|---|
| Copper Reef Lobster | Rare | Kelp Forest / Broken Crown Reef | Cage |
| Pearl Spiny Lobster | Legendary | Outer Deep Channel | Cage |
| Mossback Crab | Rare | Sunlit Shoals / Kelp Forest | Cage |
| Crown Reef Crab | Legendary | Broken Crown Reef / Outer Deep Channel | Cage |

Existing Rustclaw Lobster (Common), Blue Spiny Lobster (Uncommon), Slate Shore Crab (Common), Ivory Spider Crab (Very rare) and Ancient King Crab (Mystical) remain. There are now **four lobster species and five crab species** in ocean waters, spanning several rarities. The ocean has ten exclusive cage species in total.

**Catalogue totals:** 231 unique species overall (170 fish + 61 other creatures). Ocean open waters: 53 species; 66 including the unchanged 13-species Night Island crater lake. Lake stays at 20 species (16 fish + 4 creatures); town/lake overlap stays unchanged.

## Five new apothecary recipes

| Potion | Tier | Kept catch | Gathered ingredients | Effect |
|---|---:|---|---|---|
| Oldwater Recovery Broth | 1 | Olive Lake Perch | 2 Sunleaf + 1 River Mint | Heal 38 HP |
| Bluebar Restorative | 2 | Bluebar Trout | 2 Mooncap + 1 Ember Petal | Heal 48 HP |
| Saltwind Elixir | 2 | Copperback Mackerel | 2 River Mint + 1 Glowwing | +22% move speed for 5 seconds |
| Reefshell Phial | 3 | Copper Reef Lobster | 3 Willow Bark + 1 Mooncap | 22% damage reduction for 5 seconds |
| Seaglass Purifier | 1 | Blue Shore Squid | 2 River Mint + 1 Willow Bark | Remove poison, burn and bleed |

These are actual registered consumable items, with recipe cards, distinct potion artwork, brew timers, bottle storage, packing and normal combat effects. They use the separate consumable slot. Trophies, favourites and displayed specimens are protected; no unbanked catches can be consumed. Healing cannot revive, guard does not stack, and purification grants no lasting immunity. Existing recipe/item identities and stocks remain unchanged.

## Offshore exploration and moving Night Island

- Ocean expanded from **9,000 × 6,800 to 14,000 × 10,000**. The lake retains its existing size and connected island combat areas.
- Night Island appears only during **20:00–06:00**, at a distant offshore location beyond three current belts. All candidate sites are more than 7,500 world units from the harbour.
- Every voyage night selects a different sector and position. It remains stable through midnight and save/resume; its seed and discovery state travel with the saved voyage.
- Discover it by searching offshore. A previous night’s discovery does not reveal the next location on the chart. The chart shades the three current belts and shows current directions.
- The crater lake, water collision, landing checks and fishing marker all follow the moving island. Dawn safely boards nearby explorers at a clear water position, without teleporting visitors on permanent islands.
- Three actual current belts and an offshore eddy affect steering. Storms strengthen the flow; its speed remains capped below full boat movement speed. Anchoring still holds the boat steady, with strong-current HUD feedback.
- Lake and ocean scenery has more variation: submerged wrecks with ribs/planks/anchor debris, reef/reed gardens, stone formations, scattered shoreline stones/shells, layered island trees and paths, reeds and lily patches. Fixed an existing decoration-seed pattern that produced repeated decoration at every grid point.
- Scenery is drawn around the visible area. Night positions and rock fields are cached, avoiding full-world generation every frame. Boat steering, hull hazards, night lanterns, weather and safe-return cargo rules remain in place.
- The Deep Sea Rod is still required for the ocean. Lake access remains open. Lost voyages still lose unbanked catches; banked catches, aquarium exhibits and earlier records remain safe.

## Verification

**5,793 native Godot checks pass** in source and packed runtimes. Coverage includes prior fishing/aquarium regressions; old bait/save compatibility; actual purchase/crafting; protected fish; targeted weights and weather/night/region/method gates; new shellfish eligibility, rolls, validation and distinct unclipped images; real brewing, single claims, packing and combat consumption; forty nightly positions; midnight and resume stability; new discovery each night; dynamic landing/crater fishing; safe dawn handling; map bounds and currents; actual roe cages, unbanked recovery and safe harbour awards; JSON profile round-trip.

The release also checks archive integrity, runtime/source/server/editable agreement, clean server import and gateway/authority readiness/build. Real-device playtesting remains.

## Manual deployment

Deploy **Crossroads_v198_25_Server_Update.zip** to the existing Render service first. Confirm `/health` reports ready and build `V198.25-changing-tides`. Then upload **Crossroads_v198_25_Web.zip** to itch.io and reload clients. **Crossroads_v198_25_Editable.zip** contains the full editable project, assets and validation script.

Preserve the existing database, accounts, persistent disks, `DATABASE_URL`, signing keys, admin/report passwords and current environment settings. No database migration, reset or key rotation is required. No live services were changed or deployed automatically.
