# Authoring route-driven realms

The five v50 maps are data-authored in `content/campaigns/*_paths.json`; their Godot scenes supply the usual arrival, return, merchant and boss markers. `scripts/immersive_worlds.gd` owns collision, navigation, guardian progression, exploration rewards, environmental ticks, treehouse transitions and raft transport. `tools/build_v50_worlds.py` generates deterministic layouts and original art.

| Field | Meaning |
| --- | --- |
| `floors` | Union of walkable rectangles or hexagon polygons. `kind` selects meadow, glass, river, trail, bridge, boardwalk, log, petal or house rendering. Named floors are places; unnamed floors are connecting routes. |
| `props` | Pixel objects with position and scale. `solid` is a real trunk/base radius; 0 is decorative. Do not cover a route with an invisible collision. |
| `spawns` | Enemy kind and position. Every position needs a navigable route from arrival. Defeating original defenders awakens the guardian. |
| `checkpoints` | Route milestones set a minimum party level so secondary/passive unlock before the guardian; guardian arrival guarantees special. No checkpoint healing is added. |
| `gates` | Visible barrier rectangle and minimum progression stage. Opening a gate also rebuilds AStar collision and route caches. |
| `grass` | Foreground tall-grass rectangles. Cover both heroes and enemies, fade around allied ground positions, and never apply damage from rendering. |
| `mud` | Traversable slowdown rectangles. Terrain slowdown multiplies combat speed rather than overwriting a spell's slow status. |
| `falls` | Animated waterfall rectangles. Waterfall surfaces block walking unless a bridge explicitly crosses them. |
| `secrets` | Discovery name, position, gold/heal amount. Each player claims each discovery once. Rewards remain optional. |
| `houses` | Paired outside/inside door positions. Interiors are physical rooms with their own floor and discoveries. Interact from either side returns to the other. |
| `raft` | Two walkable docks, a travel speed and lake crossing. Only the host moves passengers; snapshot `charging` locks guest walking while aboard. |

## Layout exercise

Draw an arrival, two alternative routes, a converging combat room and a guardian room. Add at least one optional branch. Keep corridor widths above 190 so two heroes can pass. Put solid props away from arrival, defenders, doors and rewards. Give blocked ground a visibly different surface. Use `can_stand()` and `route()` to verify every required point; test the entire route, not just its endpoint. A room marker or scenic bridge without matching collision is incomplete.

Hexagon floors use `Geometry2D.is_point_in_polygon`. Other floors use rectangles inset by 16 for player clearance. Props block their visible bases plus player clearance, not their entire tree canopy. The shared 60-unit AStar grid lets melee foes travel around walls; ranged foes retreat when a direct path is available. Ordinary-enemy decoy steering also works in the previous custom realm navigators.

## Environmental timing exercise

A Solstice Cantor creates a `beams` entry with `warn`, `life`, `tick`, `radius` and position. Warning must finish before damage begins. Damage and enemy healing tick once per second; healing is capped at `max_hp`. Do not attach these effects to draw calls: drawing happens on every client, and frame rate must not determine damage. Keep hazards bounded (18 beams / 40 warnings here).

## Transport exercise

The Silverfall raft is a finite host-owned journey. It waits 1.2s for boarding, carries everyone smoothly at 260 units/s, then places passengers on a legal shore position. Interact at an empty far dock calls it back without passengers. Walking/dodge/attack handlers all reject requests while aboard; the same flag travels in player snapshots. Test two players, a late boarder, an empty return, death and a new run. Keep an alternate walking route so an optional raft never becomes a required progression lock.

## Hero example

Pippa's JSON is `content/characters/pippa.json`; runtime is `scripts/fern_combat.gd`. It demonstrates sinusoidal travelling ribbons with a per-thread hit list, finite decoys with ally-only bloom healing, a conditional team movement passive, and expanding spiral tips with independent per-arm hit lists. The tips deal at most three hits per foe in one special. Walls block contacts. Snapshots use arrays of numeric coordinates, not live Node references. Bosses are immune to decoy redirection.

## Checks

Run Godot headlessly with `--script res://tests/v50_worlds.gd` and `--script res://tests/v50_coop.gd`. Import first after generating new sprites. The tests verify every authored enemy/discovery position, required routes, progression, exits, warning/tick behavior, mud reset, rewards, treehouse return doors, raft movement/return, Pippa's finite hits/healing and serialized co-op state. Also inspect a real rendered frame: valid geometry alone cannot detect a hidden bridge, a missing texture or a hero disappearing on the raft.
