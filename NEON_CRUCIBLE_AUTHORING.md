# Extending Neon Crucible

Start with `content/campaigns/neon_crucible.json`, `content/regions/neon_crucible.json` and `scripts/neon_crucible.gd`. This realm shares the ordinary hero kits and co-op systems; its progression is a sequence of uploaded boss bodies.

## Data
- `size`: world extent; keep the region's size identical. Navigation derives its grid from this size.
- `rooms`: named rectangles `[x,y,width,height]` and a glow `colour`. Include smaller unnamed rectangles for connecting bridges. Room interiors shrink by 18 units for collision, so overlap connections by at least 40 units. All rooms and props are drawn only when near the camera.
- `props`: `kind`, `pos`, `size`; optional `solid` defines a matching blocking rectangle. Available visuals: `server`, `coolant`, `forge`, `antenna`, `belt`, `console`. Omit `solid` for flat decorative belts. Collision padding is 18 units. Never place a spawn, body, exit or pod inside a solid prop.
- `spawns`: machine `type`, `pos`, `sector`. Sector 0 is the first objective. Place the six roles in mixed, separated clusters. Do not put every ranged enemy in a row.
- `bodies`: ordered entries with machine `type`, `name`, `pos`, `hp`. Defeating one creates a 2.5s upload and spawns the next elsewhere. The final entry unlocks the exit. You can add another entry using an existing `continuum_*` type. Its health scales with the number of players through the shared spawn helper.
- `pods`: `id`, `pos`, `sector`; clear that sector to use it. Repairs are once per player per pod and do not count as spell healing.
- `exit`: accessible location inside the final area. Keep `Points/Boss` in `scenes/realms/neon_crucible.tscn` aligned with it so the ordinary portal also appears in the right place.

The scene has the ordinary Spawn, ReturnGate, Merchant and Boss markers. Runtime room geometry comes from the campaign data; an empty editor scene is expected. Run F5 to see the rooms and machine props.

## New enemy tactics
The current six roles and four chassis are listed in the module's `TYPES`. To invent a completely new type, add a JSON enemy file and manifest entry, original sprites, its name to `TYPES`, a `skill` branch and any movement/body-size logic it requires. Use the shared projectile system or bounded warned hazards; do not damage from draw functions. Keep ranged movement using `direction(..., true)` so melee players must close distance.

Turret emergence uses a separate replicated hatch state. Buried turrets cannot be hit; the hatch is visible and the objective arrow can point to it. Stuns and slows use the shared status system. Defeated bosses cancel their pending hazards. Repair Wisps cannot repair dead bodies or exceed maximum HP.

## Multiplayer
Only the host runs combat and uploads. `snapshot` / `receive` transfer the body index, upload countdown, hazards, hatches, wrecks and used pods. Clients draw that state. An intermediate boss death must not set ordinary `boss_defeated` or end the co-op match. Use `on_defeat` for this interception, and finish through `interact` only after the last chassis.

## Verify
Run `tests/v49_robot.gd` with Godot's headless mode. It validates authored spawn locations and navigation paths to every body, then defeats all four bodies and interacts with the exit. When you change the number of entries, update any test that intentionally expects four. Playtest the altered route and difficulty with a melee hero and a ranged hero; automatic connectivity checks do not judge fun or balance.
