# Deepwell Mine — player and development guide

## First visit
1. Walk to the mine west of town, south of Ram Descent, or use Profile → Visit my mine.
2. Commission the starter camp for 80 of your 120 Mine Gold.
3. Use the visible Hire button to add a second digger. The Mine tab's right column also contains boosts, shaft construction and individual crew cards; scroll to reach them.
4. Collect the depot. Reinvest in crews, transport and storage, then open the next shaft.
5. Use Buildings to upgrade machinery. Milestones & geology contains rewards and discoveries. How it works explains the full system.
6. Download your profile before leaving a shared computer. The mine's Back up profile button downloads the same complete player bundle as Profile.

Mine Gold is different from adventure gold. Ore and gem fractions accumulate continuously. Gold and ore each use one depot unit; gems use ten. Collecting moves the stored supplies into the spendable wallet. Nothing leaves the mine economy to improve heroes or buy combat equipment.

## Growth
- Twenty shafts, each 30 metres deeper; twelve diggers per shaft.
- Eight types of buildings, each with up to 25 levels.
- Mine level grows with lifetime ore output, up to level 50. Depth unlocks also require appropriate air and drainage equipment.
- Six named geological zones and twelve one-time reward milestones.
- The depot can be enlarged for longer absences. A full depot is a safe pause, not a loss of inventory.
- Boosts speed one part of the operation. If another part is the bottleneck, a boost may have little benefit; check the recommendation before upgrading.

## Saved state
All mining state lives inside `progress.mine` in `profile.json`, including wallets, stored and lifetime resources, crews, building levels, construction and refining jobs, boost expiry/reuse times, claimed milestones and timestamps. There is no separate installation or account login. An exported ZIP is a snapshot: bring the newest file when changing computers. Separate copies on two computers do not merge into one remote account.

Offline catch-up is bounded to 24 hours per absence and available depot space. Reopening the game integrates elapsed time and completes due work orders. Active boosts apply only until their saved expiration. Returning after a long absence does not loop through thousands of game frames. A backward clock earns no extra production. Local-clock progression is suitable for this personal side game, not an authoritative money or leaderboard service.

Testing protects normal profiles: Playtest disables mine actions; Game Dev previews a fully upgraded temporary operation. Exiting restores the saved account, which then catches up ordinary idle time. No hero/mastery/daily-damage rewards are earned from mining.

## Student development / future expansions
- `content/mine-catalog.json`: tune building prices, unlock depths, work times, descriptions and geological zones.
- `scripts/idle_mine.gd`: production, affordability, job scheduling, resource integration, milestones and versioned save validation.
- `scripts/idle_mine_view.gd`: dashboard, controls, economy explanations and responsive layout.
- `scripts/idle_mine_cutaway.gd`: gallery and building artwork/animation, with visible-area culling.
- `scripts/idle_mine_town.gd`: town doorway and its sign/rails/fan.
- `tests/v133_mine.gd`: offline, profile, economy and protection checks.

When extending saved fields, upgrade the schema and migrate existing data before changing validation. Retain stable building/milestone identifiers. Keep current shaft and crew caps consistent between catalog, validation, buttons and milestones; deeper expansion needs updates to those limits and descriptions. Keep production bounded and keep mining transactions independent of adventure gold.

Possible class investigation: compare two upgrades' costs and increased output, estimate their payback time, find the bottleneck, then test the prediction. Record a short first-visit and overnight-return test, including the mining profile backup. This also gives Business students a resource-management model to analyse.

## Research inspiration
The production chain, capacity decisions and reusable timed boosts were informed by the official Idle Miner Tycoon descriptions of mining, elevator/warehouse capacity and manager boosts. FX's mine has its own rules and progression, without advertising, paid boosters or copied artwork.

- https://www.kolibrigames.com/blog/what-happens-in-one-hour-of-idle-miner-tycoon/
- https://www.kolibrigames.com/blog/lets-dig-in/
- https://hyperhippo.com/games/adventure-capitalist/

## v144: Metal seams and furnace

Open Adventures → Build, trade & create → Idle Mining. Six metal seams unlock at shafts 2/4/7/11/15/18. Collect Depot, then use Smelter & metals to turn each metal ore plus coal into bars. Market prepares those bars as sale stock; shafts and buildings from depth 5 also need bars. Deliver reinforcements once to shorten remaining construction time by 35%. All new stock and orders are part of your player profile. See UPDATE_V144.md for recipes.
