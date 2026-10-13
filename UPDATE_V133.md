# v133 — Deepwell Mine

The old mine entrance below Ram Descent is now a self-contained idle mining game. Enter using E / Interact, or use **Profile → Visit my mine**. Your hero's attacks, combat currency and statistics do not participate in this economy.

## Build your operation
Start with a separate grant of 120 Mine Gold. Commission a starter camp for 80, then hire a second ram digger immediately. Crews excavate continuously, an ore lift carries their output to the surface, and the depot stores Mine Gold, ore and gems. Collect the depot before spending its contents.

Grow from one shaft to twenty shafts, reaching 600 metres, with up to twelve ram diggers per shaft. Lifetime ore production raises Mine level and unlocks access to deeper excavation. Construction requires collected resources, appropriate ventilation and, deeper down, drainage. One construction crew works at a time; cancellation returns the paid resources. Existing diggers continue working while a job is underway.

Eight building types develop the mine: Ventilation House, Ore Lift, Surface Depot, Tool Workshop, Ramforge Smelter, Crystal Assay House, Drainage Station and Clockwork Drillworks. New buildings appear in the animated cutaway as they are built. Six geological zones change gallery colours and mineral details. Pickaxes move, mine carts travel, fans rotate, the lift moves and a working smelter gives off smoke.

## Make decisions
Too little fresh air reduces digging efficiency. A slow lift limits surface throughput. A full depot stops new production safely; it never removes stored resources. The interface shows these three constraints and recommends the next useful improvement. Hiring more crews is not always the best purchase.

The smelter converts collected ore into Mine Gold through a separate 30-second work order. Three free boosts have cooldowns:

- Crew Rally: twice the digging output for 60 seconds; five-minute reuse timer; shaft two.
- Vent Flush: twice the air supply for 120 seconds; ten-minute reuse timer; shaft three.
- Gem Survey: twice the gem recovery for 180 seconds; fifteen-minute reuse timer; shaft three and an Assay House.

Twelve claimable milestones reward mining achievements with mine resources. The ledger tracks depth, crews, Mine level, lifetime production and refining. Its geology journal explains discovered deposits.

## Idle progress and profiles
Crews work while you play other activities. When the game is closed, production is calculated on your return, with up to 24 hours of catch-up per absence and the depot's capacity as a limit. Construction, refining and boost expirations are accounted for. The return report shows resources produced since the previous mine visit.

This is local profile progression, not a login account or server process. The entire operation is stored under `progress.mine` in your existing downloaded player ZIP's `profile.json`. Export before leaving a shared computer, then upload your newest profile on another device. New Game clears this device's mine too; the warning now says so. Loading an older profile without mining data starts a new mine without discarding its other progress. Offline production follows the device clock; clock manipulation is not a verified competitive system.

Playtest is read-only for mining. Game Dev provides a temporary twenty-shaft, fully upgraded preview and does not overwrite the normal saved account. Normal idle catch-up applies again when the original profile is restored.

## Performance and extension
Offline progress uses a small number of analytic intervals, rather than simulating every missed frame. Routine mining updates run at five-second intervals outside the mine. The cutaway animates at up to 15 updates per second and draws visible galleries; the town's gameplay process and world drawing stop while its dedicated mine interface is open. The interface supports touch scrolling.

Mine costs, building descriptions and biome appearances are in `content/mine-catalog.json`; rules and schema validation are in `scripts/idle_mine.gd`. See MINE_GUIDE.md for play and development notes.

No official hero abilities, artwork or combat balance changed. Render's room-service files remain the same as v132.
