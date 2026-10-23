# Crossroads: Realms Beyond — v198.33

## Fish selling and display income
- Each sale row explicitly says TROPHY SIZE or Not trophy, shows its weight as a percentage of the species average, and includes the existing illustrated size-rank meter.
- The five-tank comparison strip shows every displayed fish, weight and hourly visitor income. Displayed/favourite/rare/trophy fish retain sale confirmations.
- Storage location, transfer buttons, newest sorting and batch selling work together; smaller screens scroll naturally.
- Aquarium rarity now drives income. Common trophies earn at most 1 Glimmer/hour, ordinary common fish zero; ordinary very rare fish at average weight earn 6/hour; large trophy legendaries earn 18/hour. Mystical/Fabled fish remain above legendary. Existing collected currency and pending aquarium units are retained.

## Carrying, storage and voyages
- Carrying bag: 4 fish initially, 6 at fishing level 5, 10 at level 10; no further automatic growth. Existing packing perks add space.
- Separate Ripple & Reel storage: 20 fish initially, eight +10-space upgrades, maximum 100. Upgrades cost 250, 500, 750 … 2,000 Glimmers (9,000 total).
- Storage & sales is accessible inside Ripple & Reel and from the marina's selling shortcut. Drop off the whole bag, or transfer individual catches between bag and storage.
- Voyage catches go directly into Ripple & Reel storage on a successful return. Boat cargo still starts at 20, with existing Trailcraft upgrades. Released fish take no cargo space and their pending XP still requires returning alive.
- Check free storage before sailing. If storage fills, the landing manifest preserves cargo and offers release for XP; it never silently deletes fish or overfills storage. Release-only landings work with preserved legacy overflow.
- Old collections are preserved: first four fish stay carried, excess moves into storage. If an old collection exceeds the new storage allowance, it remains safe; sell, withdraw or upgrade before depositing more.
- Fish IDs, journal, discoveries, favourites, tanks, XP, accounts and keys are retained. No DB reset or deployment performed. New storage metadata validates in JSON saves and is cleaned up after selling or recipe consumption.
- Voyages still cannot be suspended/resumed. Quit or KO loses unbanked rewards.

## Town
- Removed cottage-roof cargo, added bank-side barrels, rope and a drying rack.
- Fixed timber beams crossing the Cliffside Cottage and Willow Court doors, including embedded runtime artwork.
- Camera restore, Dev Desk and developer time/weather buttons move below the upper HUD controls.
- Challenge Lodge shifts 250 units west, with matching collision, interaction, paths, facade windows, torches and light sources.
- Added Crossroads Market Office above the market with a path, collision, steps, signage, planters and night lighting. Its enterable information hub previews future mining/fishing/gathering/trading ventures. No new business economy is enabled yet.

## Validation and deployment
- Native Godot storage/selling/town checks, voyage regression checks and Citadel/fishing/crafting checks: see bundled validation logs for exact results.
- Desktop and 844×390 selling layouts inspected; day/night marina and Market Office reviewed.
- Server, editable source and patched web PCK compared for changed runtime files. Clean gateway/server health checked locally without a production DB connection.
- Remaining: real-device/browser playtesting and production-DB integration after manual deployment.
- Deploy the server update first, preserving the existing Render service, environment, database and keys; then replace the itch.io web upload. Do not delete/recreate your database.
- Windows Defender clearance remains unverified; this environment cannot reproduce the previous Windows detection. No bypass/exclusion is recommended.
