# Authoring a school adventure

School layouts and encounters are in `content/schools/elementary.json`, `middle_school.json` and `high_school.json`. Their region files point to this data using `school_campaign`. `scripts/school_world.gd` supplies the shared controller for solo and co-op.

## A safe student assignment

1. Make a backup of the editable project. Choose an existing school's classroom or hallway.
2. Move furniture or add an existing prop kind. Keep wide paths around desks and door openings.
3. Move a patrol or change one enemy type to another existing school enemy. Keep starting points outside furniture and locked doors.
4. Write clearer objective text, room names or a bell-gear name.
5. Press F5, enter that school and walk the full route. Try melee and ranged heroes, then co-op.

| Field | Meaning |
| --- | --- |
| `rooms` | Walkable rectangles `[x, y, width, height]`; overlapping rooms form connected halls. Themes select tile, wood, carpet, yard, roof, street or exam scenery. |
| `doors` | Unique ID, center `pos`, `size`, prerequisite `requires`, and locked-door `label`. An empty prerequisite allows Interact to open the door. |
| `props` | `kind`, center `pos`, display `size`; optional `solid` gives its collision size. |
| `groups` | Named arrays of enemies: existing `type`, starting `pos`, and `hp`. |
| `stages` | Ordered objectives; classroom groups, boss and trigger rectangle are configured here for Elementary. |
| `gears` | Middle School wing IDs and collectible locations. Clearing the matching group enables collection. |
| `departments` | High School wing IDs, boss types and spawn locations. All three guardians unlock upstairs. |
| `routes` | Stair markers with `pos`, destination `end`, and prerequisite. Destination points must be walkable. |
| `spawn`, `exit`, `merchant` | Street markers; preserve a reachable exit after completion. |

Specialized Middle and High progression is implemented in the controller; changing their objective order or adding more departments requires a script change. A new enemy ID also needs an attack implementation and registration in `TYPES`; merely naming a new `custom_attack` does not create behavior. Enemy base stats are editable in `content/enemies/`.

`tools/create_v44_school_content.py` and `tools/create_v44_school_art.py` are the original authoring sources. Running them regenerates school content or assets and overwrites edits to those generated files. Edit the generator if you want repeatable changes; edit JSON directly for a small classroom assignment. Keep backups.

Door rectangles must span the entire connecting passage. Account for overlapping room rectangles: a door inside one room can be bypassed through its neighbor. Keep remote upper floors separated from ground-floor geometry and use paired stair markers to travel between them.

## Automated checks

From the project folder:

```sh
godot --headless --path . --script res://tests/v44_schools.gd
godot --headless --path . --script res://tests/v44_coop.gd
```

Use the actual path to your Godot executable if `godot` is not on PATH. Tests exit with a nonzero status on failure. They verify progression, accessible encounter positions, sealed entrances, boss patterns, exam persistence and replicated co-op state. They supplement walking the map; they do not judge combat balance or replace a phone/browser playtest.

The older `content_manager.py` validator predates these specialized campaigns and newer ability styles. Do not use its registry-refresh workflow to rebuild this expanded project's manifest. Preserve existing manifest entries, including `quest_regions`, when adding content manually.
