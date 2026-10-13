# Edit the Crossroads town in Godot

Open `scenes/town.tscn` in the Godot 2D editor. Save changes with Ctrl+S, then press F5. The game reads this scene each time it enters town. It uses the markers and artwork positions for the running map.

- `GroundPaint` holds Polygon2D road and plaza shapes. Use the 2D polygon handles to change their areas. The `tile` metadata determines the game tile (`path` here). Later patches cover earlier ones.
- `Landmarks` holds visible sprites: Character Hall, Supply Shop, portal, Elder Ram, lamps, and banners. Drag a Sprite2D to move it. The optional `label` metadata supplies the sign shown in the running game. Give new decorative sprites a PNG in `assets/` and select it as the Texture.
- `Points/Spawn` positions the character on entry. `Points/Elder`, `CharacterHall`, `SupplyShop`, and `Portal` are invisible at runtime. Their `menu` metadata selects what opens when the player presses E near them; their `hint` metadata provides the prompt. Move each interaction marker along with its artwork. Keep the node names and containers.
- `Floor` is the editor backdrop. The playable bounds come from `content/regions/town.json` (`size` 1800 × 1100). Keep the backdrop consistent with those bounds.

The shops are visually distinct and their interaction points sit by the entrances. The scene is an authoring scene: the game script draws the sprites and tiles at its positions. Character definitions, inventory and realm portals still live in `content/` and the game code. Town landmarks currently do not block movement.


## v65 town services
New architecture is scene-owned in `scenes/town.tscn` using editable SVG assets: `character_hall_v65.svg`, `supply_vendor_v65.svg`, `pond_food_stand.svg`, `healer_shack.svg`, `wayfinder_lodge.svg`, `seedhouse.svg`, and `town_construction.svg`. These SVGs use flat colors and crisp geometry to match the existing game art. The Character Hall still opens `characters`; Bartle's interaction still opens `supplies`.

`scripts/town_upgrade.gd` contains the cook, healer, scout, gardener, carpenter, additional benches/statues and collision rectangles. Its `POINTS` and `CLINIC_SPAWN` match the scene marker locations. If moving a building, update its scene art, marker, module point, collision rectangle and path patch together. Leave at least one walkable approach to its NPC. Avoid placing a roof over a neighboring service. Existing residents and guard patrols continue in `town_life.gd` / `town_scenery.gd`.

Wayfinder filtering uses authored difficulty labels without changing portal ordering. Seedhouse crop and food state save locally through `provisions.gd`. Defeat sets a clinic return flag; normal town visits still start at the plaza. Multiplayer Town transfer preserves the chosen hero and sets the clinic flag when returning after defeat. In-match PvP respawns stay in the arena.
