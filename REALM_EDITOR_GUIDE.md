# Build a realm visually in Godot

The built-in layouts are `scenes/realms/grove.tscn` `scenes/realms/quarry.tscn`, and `scenes/realms/sunfield.tscn`. Open either scene in Godot's 2D editor. Its visible sprites are **authoring markers**: the running game reads their positions and IDs when the realm starts. It draws its own HUD, tiles, enemies, and collision at those positions. The script does not use the old enemy coordinate list.

## The scene tree

- `Floor`: a coloured editor backdrop showing the map bounds. Set its polygon to match the size in the realm JSON.
- `GroundPaint`: Polygon2D patches. `Road` is the first example. Select it and edit the polygon points visually; its Inspector metadata `tile` is one of `grass`, `forest`, `ash`, `path`. Add more Polygon2D children to paint other ground zones. Later patches cover earlier ones. This paints **zones**, not individual TileMap cells.
- `Points/Spawn`, `Points/ReturnGate`, `Points/Merchant`, `Points/Boss`: drag these visible markers. Keep their names and parent folder exactly as written.
- `Enemies`: each Sprite2D represents **one placed enemy**. Duplicate a marker with Ctrl+D, move it in 2D, and set its Inspector Metadata `enemy_id` to an installed enemy ID, such as `archer` or `warlock`. Also change its Texture to that enemy's `_0.png` so the editor preview matches. The marker's position, not the filename, controls the run. Summoned minions do not need markers.
- `Obstacles`: duplicate a tree or crystal Sprite2D, move it, and set Metadata `kind` to `tree` or `crystal`, and Metadata `radius` to its collision radius (43 is the default). The running player slides around these markers. Keep an open route between spawn, enemies, merchant, and boss.

In Godot, select a node in the Scene tree and use the move tool in the 2D viewport. To find Metadata, scroll to **Node > Metadata** in the Inspector. Save the scene with Ctrl+S, then press F5 and enter its portal. You can test changes without manually editing enemy coordinates.

## Create a new realm

1. Make a copy of an existing realm scene in File Explorer, for example `scenes/realms/grove.tscn` to `scenes/realms/moonwood.tscn`. Open the new scene in Godot. Rename the root, edit `Floor` bounds, draw `GroundPaint` polygons, and move/add enemy and obstacle markers.
2. Copy `content/regions/grove.json` to `content/regions/moonwood.json`. Change `id` to `moonwood`, `name`, `scene` to `res://scenes/realms/moonwood.tscn`, and adjust `size`, `terrain`, `boss_health`, `boss_secondary` (`stomp`, `fireball`, or `sunburst`), and `boss_split` if desired. Enemy and point coordinates come from the scene.
3. Keep at least `9 × xp_per_level` placed enemies so the player can reach level 10. At the default 5 kills per level, use at least 45. The scene checker rejects unknown enemy IDs and missing marker groups.
4. With Python/Pillow available, run `python tools/content_manager.py --refresh` and then `--check`. On a school computer without Python, open `content/manifest.json` and add `"moonwood"` to its `regions` array, retaining commas and quotes.
5. Test by selecting the new realm at the central portal. Walk the whole level, use the merchant, defeat all placed enemies, fight the boss, and leave via the exit. Export/share a new build for others.

`examples/sunfield_realm_submission.zip` is a working practice realm: it contains a region JSON and editable scene. You can extract those two files to their matching project folders, add `"sunfield"` to `manifest.json` under `regions`, and open `scenes/realms/sunfield.tscn` to practise moving markers. Or install it with `python tools/content_manager.py --install examples/sunfield_realm_submission.zip` if Python and Pillow are available.

## Add an enemy to a visual realm

Install its JSON and two PNGs, then add its ID to `content/manifest.json` under `enemies` (the installer handles the manifest when available). In the realm scene duplicate an enemy marker, move it, change Metadata `enemy_id`, and pick its `_0.png` in the Texture field. The example `examples/lantern_moth_enemy_submission.zip` contains an installable ranged Lantern Moth. It is already placed in the Grove in this version; its definition alone does not spawn it in any other realm.

Scenes are reusable Godot resources: student layouts stay editable in the 2D editor. The content installer accepts only JSON, PNG, and `.tscn` realm files and checks submitted scenes for supported nodes and assets. New scripts and novel gameplay effects are teacher-reviewed code work.
