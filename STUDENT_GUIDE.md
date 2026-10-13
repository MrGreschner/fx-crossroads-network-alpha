# Extend FX Crossroads

Copy a working example, choose a unique lowercase ID with letters, digits, and underscores, and submit a ZIP with project-relative paths. For instance, include `content/characters/book.json` and four `assets/book_*.png` poses. Standard submissions contain JSON, visual realm scenes, and PNG only. The teacher reviews and playtests each addition.

The original content installer predates many specialised hero kits; its old limits can reject a valid modern custom ability. For these kits, use the current catalogue and teacher review, register the hero in the manifest, and run the Godot checks.

For original basic content, from a terminal opened in the project folder, run `python tools/content_manager.py --install your_submission.zip`. The installer validates in a temporary folder and refreshes `content/manifest.json`. Run `python tools/content_manager.py --check` before exporting. Install Pillow for the validator with `python -m pip install Pillow`; Godot itself does not need Python. On Windows, use `python` rather than `py` if the launcher is missing. Publish a new itch.io export to share updates.

## Character assignment

Duplicate `content/characters/ram.json`, change the ID, name, stats, `run_cost`, sprite prefix, abilities, and passive. Draw four transparent PNGs named `<sprite>_idle.png`, `<sprite>_walk1.png`, `<sprite>_walk2.png`, and `<sprite>_attack.png`. Current hero art normally uses 64 × 64 pixels; keep scale and baseline consistent with the hero you copy. Copy the numbers from similar existing characters and test at levels 1, 3, 5, and 6. A range primary should have a longer cooldown. Start with `ABILITY_CATALOG.md` for the complete hero checklist, implemented styles, statuses, passives and both mastery techniques. The Character Hall reads new heroes from the registry. Keep a separate editable image source for marking.

## Enemy assignment

Duplicate a definition under `content/enemies/`. Pick one of `chase`, `charger`, `ranged`, `burst_ranged`, `dual_ranged`, `homing`, or `summoner`, then draw four 28 × 28 PNG poses. `flying: true` allows the enemy to pass obstacles; omit it for ground creatures. A ranged shot normally stops at scenery. To actually see your enemy in a realm, open a `scenes/realms/*.tscn` in Godot, duplicate a marker under **Enemies**, change its `enemy_id` metadata to the JSON ID, select its `Sprite2D` Texture for the editor preview, and save the scene. The texture preview alone does not change the in-game enemy ID.

## Item assignment

Duplicate `content/items/potion.json`. Choose name, ID, cost, effect, and amount. The shop scrolls and shows item explanations; both the town shop and realm merchant read the manifest. Effects include `heal`, `invulnerable`, `bonus_damage`, `bonus_speed`, `lifesteal`, `shockwave`, `haste`, `armor`, `block_boost`, `bonus_health`, `reflect`, `cooldown`, `bounty`, `thorns`, and `revive`. Ask the teacher to test unusual combinations and prices.

## Realm assignment

Copy an existing `scenes/realms/*.tscn` and matching `content/regions/*.json`. In Godot 2D, move the Spawn, ReturnGate, Merchant, and Boss markers, drag enemy markers, change their `enemy_id`, place trees/rocks/other approved obstacles, and paint ground polygons. Preserve the required node names. The JSON identifies scene, name, dimensions, terrain, boss health, and boss secondary. Add at least `9 × xp_per_level` enemy markers. `REALM_EDITOR_GUIDE.md` explains each click. Realm speedruns are solo through the main portal; the co-op room option shares the realm adventure with teammates.

## Small scenery assignment

Make one transparent 32 × 32 plant, rock, sign, or other prop in Piskel. Export a PNG plus editable source, preview it against two realm backgrounds, and hand both in. In Godot, a realm designer adds a `Sprite2D` using your PNG. Decorative props go in `Decorations`; solid props need an `Obstacles` marker with metadata `kind` and `radius`, plus a sensible `radius` metadata value. Existing `tree`, `crystal`, `ice_pillar`, `satellite`, and `barricade` keys already work.

## Multiplayer and playtesting

The Render room service at `wss://fx-crossroads-rooms.onrender.com` exchanges room invitations. A student hosts, shares a six-letter code, chooses the mode, and presses Start. Direct WebRTC links carry the match; the host browser simulates enemies and damage. The host leaving ends the room. Gate Defense supports 1–3, Arena 2–4, 2v2 exactly four, co-op realm exactly two, and Ram Descent solo. Test network play in a Godot Web export in the intended school browser. The legacy practice ZIPs under `examples/` still demonstrate installation.

## New attack examples (v23)

The base attack sheet is `ABILITY_CATALOG.md`. It now includes waterfall waves, bouncing projectiles, timed seed bursts, spiral darts, orbital shards, vortex fields, splash homing shots and the new level-five passives. Copy `ferryman.json`, `sunflower.json` or `spindle.json` for complete examples. Use only the listed styles unless your programming group is extending the shared combat controller.

## Quest writing and world contributions (v42)
See QUEST_AUTHORING_GUIDE.md for adding NPC dialogue, quest chains, prerequisites, objective markers and encounters. Validate new campaign content with `python3 tools/validate_quests.py`. Quest data is separate from realm data; the existing hero/item workflows remain available.

## Construct and expert-enemy examples (v43)

The updated base sheet, ABILITY_CATALOG.md, includes `bloom_seed`, `echo_brand`, `spell_snare` and `soul_ledger`. Copy `content/characters/sunflower.json` or `veyra.json` to experiment with delayed plants, movement-sensitive damage, projectile capture and linked targets. Try each at its unlock level, then test in a party: friendly healing must exclude opponents, and a projectile snare must preserve teammates' shots.

Ebonwake's enemy definitions demonstrate healing, warned gravity pulls, a finishing window before resurrection, limited minion nests and transformation. Their shared implementation is `scripts/v43_expansion.gd`; its arrays synchronize through host snapshots. Keep explicit caps and visible warnings when designing a new effect. Extending this realm's floor requires changing its connected rectangles and navigation grid as well as the scene markers. Run `tests/v43_expert.gd` after changes and perform a real Web co-op playtest before publishing.
 

## School adventures (v44)

Use SCHOOL_AUTHORING_GUIDE.md for layout, furniture and patrol assignments. Its school workflow preserves the expanded manifest and covers specialized campaign logic. The legacy content installer above predates these campaigns and newer abilities; do not refresh the expanded manifest with it.

## Rook and chain-fighter experiments (v45)

Copy Rook Ironhand for a moving-flail or grapnel assignment. ABILITY_CATALOG.md lists the three new styles and their numeric fields. Change one variable at a time and compare accuracy, damage per second and wall behavior. Include a melee-versus-ranged playtest and verify that co-op allies never take damage.

## Original hero overhaul and Iris (v46)

The four original heroes now demonstrate distinct attack artwork and synchronized effects. Living Book adds a held-input channel with explicit cancellation; Dribble demonstrates moving the actual actor between targets. Iris demonstrates persistent line geometry, consuming those lines into projectiles, and a slowing damage field. Use ABILITY_CATALOG.md and the matching JSON files to explore these styles. Test release, stun, death and a new run so temporary effects cannot leave players stuck.

## Stateful buff assignment (v47)

Garrick demonstrates a three-step ability cycle, temporary outgoing damage/movement/protection modifiers, a conditional cleanse, and a staged special. See the new Runebearer rows in ABILITY_CATALOG.md. Check the next-rune indicator, timer expiration, cooldown, new-run reset and remote-player behavior when modifying this kit.


### v48: separating movement from animation
Study Tumblebrew in `scripts/v48_combat.gd`: its ground position moves smoothly along a collision-checked path, while `visual_offset` lifts only the sprite for each hop. Three landing events leave poison puddles; a per-cast list prevents repeated landing damage or healing on the same enemy. The host owns this state in multiplayer. Alderjaw demonstrates a delayed lane attack: mark the tree's path, animate the fall, then check targets at impact. His defensive passive stores a timer for each different stunned foe, so repeated stuns cannot build unlimited armour. Change balance values in the character data and keep descriptions in agreement with runtime behaviour.


### v49: build a transformation, not a second character
Bolt Ironcore keeps his health, inventory and hero identity while Iron Tempest temporarily changes his Primary, speed and visible body. `robot_combat.gd` owns the form timer; `effective_stats` gives Stomp its own damage/cooldown while the form is active. Both local and host attack handlers reject other attacks and dodge during the form. Drawing never applies damage. The host checks saw contact at timed intervals; clients only receive snapshots.

For a bigger adventure, Neon Crucible demonstrates connected room rectangles, visible solid machine props and an ordered `bodies` array. Continuum's first three defeats are intercepted, so they cannot trigger the ordinary victory portal. Add another uploaded chassis by extending data; use the authoring guide and verify every new body's location has a route from the spawn. Guided missiles, beam warnings, repair support and circuit fences are new examples for student enemy designs.

### v50: design a place, not an enemy field

Use `IMMERSIVE_REALMS_AUTHORING.md` to build a route-driven layout. Honeyglass demonstrates hexagonal rooms and branching maze corridors; Sunfield demonstrates a narrow arrival and foreground concealment; Lantern Marsh demonstrates forbidden ground, temporary terrain slowdown and optional reward branches; Silverfall demonstrates converging routes, separate treehouse interiors and a shared moving raft. Petalbrook combines ribbon paths, hollow-log passages and a cute woodland guardian.

For an assignment, add one optional route and one discovery without breaking the arrival-to-boss path. Test collision, defender navigation, door return trips and completion. Pippa adds three ability patterns to the catalog: travelling intertwined ribbons, a finite decoy with ally bloom healing, and three expanding spiral tips. Keep damage in host-owned update functions and artwork in draw functions. Explain how your attack looks before checking its damage: players should be able to infer where it reaches and when it lands.

### v51: a visual walking gait
Dribble demonstrates a visual ballistic bounce with landing squash in `basketball_motion.gd`. The sprite rectangle changes, but the actor’s ground position stays fixed for collision and targeting. Infer movement from actual displayed positions rather than treating every remote player as walking. Finish the current hop when movement stops and reset after teleports or scene transitions.

## Frostguard skating cadence (v52)
A 0.36-second slide and 0.24-second stop preserve average walking speed. The movement helper integrates travel time across phase boundaries rather than sampling a speed once per frame. Input release never resets the cadence. Ice streaks follow actual position changes; collision and status modifiers still apply.

## Town routines and wishing well (v53)
The five decorative residents use three-point routes: walk for five seconds, work for three, then repeat. Edit residents in scripts/town_life.gd to change species, clothing, route or task. Keep routes clear of entrances and structures. They do not affect combat or hero selection.
The well checks gold and pack capacity before charging; each paid toss rolls 1–100 and only 1 wins. Rewards use existing item IDs and the normal loadout, so they work in a run like shop items. Chance, cost and prizes are explained to players.

## Town scenery and matching sprites (v54)
scripts/town_scenery.gd keeps scenery, lightweight animation, collision and ram patrols together. Patrols follow authored waypoints and reverse towards the gate. The pond draws four fish along elliptical paths; the campfire uses moving flame tips and rising sparks. Fairies fly between trees and disappear periodically. Keep tree bases and structures clear of entrances when changing coordinates.
tools/build_v54_poses.py rebuilds the three original heroes' simplified attack poses from their walking images. Use the same pixel grid, palette and silhouette for poses so their appearance stays consistent during movement and combat. Attack effects are handled separately.

## Lure, explosion and healing phases (v55)
Fern Double uses explicit phases. Only the lure redirects enemies. At expiry it damages nearby enemies and slows them and tracked lured targets. The healing phase emits three one-second ticks; large frames carry elapsed time between phases and preserve the total. Every tick checks range, walls and team allegiance, then credits actual healing to the caster. Snapshot both the phase and tick count so guests show the right animation without applying damage or healing themselves.
Mara’s dawn_circle demonstrates matching a visual boundary to the actual damage radius. Its persistent visual effect does not cause extra damage ticks.

## Held attacks and moving formations (v56)
Dustdevil demonstrates a timed defensive input: the host tracks primary-held state and aim, tests swept projectile segments against the nozzle, removes one caught hostile shot, then creates one returned shot on release. A short catch window, one-shot capacity, expiry and input timeout keep it fair. Ally projectiles are excluded. Mobile aim-stick release follows the same route.
Cloudloom's three-cloud formation and Cairnheart's rampart use per-target hit lists to prevent continuous animation from repeatedly dealing full damage. Tailwind Seam checks team, distance and wall visibility on each tick. New visuals and mechanics use the same points and ranges; guests receive the state rather than simulating extra hits.
tools/build_v56_heroes.py rebuilds the three hero definitions and matching pixel sprites. The current JSON descriptions appear in the Character Hall.

### v58 additions
Velvetwing demonstrates converging projectile geometry, traps that trigger when a moving enemy crosses a line, and moving contact areas with per-target hit limits. Her flight lives in `scripts/wing_motion.gd` so animation does not change collision or movement speed. Chip Shot demonstrates delayed fragmentation: a parent lob creates six child lobs on landing; children never split. See `ABILITY_CATALOG.md` for editable fields. School floors now use the union of connected rooms before applying their exterior wall clearance.

## v59 design exercises
Compare Caelum's temporary body with an ordinary summon: it can save its owner, but enemies can defeat it first. Keep its timer and health visible.
Wanderlight records four shot origins and replays them without recording the echoes again. Change delay or damage while preserving wall checks.
Dustdevil demonstrates timed status effects: six seconds between pulses, four poison ticks of 3 damage, and no friendly targets.

## v60 design exercises
Caelum shows how to build an illusion without a second controller: copy movement deltas and accepted casts, use identical artwork and labels, and check the copy against walls. Explain why copying intent is different from giving a summon its own target-seeking AI.
Wanderlight shows a two-state combat system. Start Earth; replay the history; then switch state. Infuse projectiles at redirection time so a later element switch cannot change a bolt already in flight.
Earth combines an immediate poison burst with delayed root growth; Fire combines an immediate burst with lingering terrain. Separate warning, active duration and status duration, filter friendlies, and cap active terrain.

## v61 design exercises
Kage's returning shuriken uses two hit lists: one outward, one returning. Explain why one global hit list would prevent the return attack, while no hit list would damage a target every frame.
His Eightfold Eclipse combines a per-star hit list with a total three-hit limit. Trace how both limits keep a dramatic eight-star effect balanced.
Rook separates chain contact (slow) from flail-tip contact (damage). Grapnel healing checks actual health lost and records each target once.
Bolt's extra time is awarded on confirmed defeat, rather than on every damage event. Test nonlethal hits, training dummies, revivals, co-op kill attribution and PvP defeats.

## v62 design exercises
The Agent is a ray-tracing exercise. Find the first intersection with a target or wall for each shotgun ray, then compare this with a piercing beam which can hit every intersected enemy.
Plan all seven rays before changing enemy health: otherwise a target killed by the first ray might disappear and let later rays incorrectly pass through the same burst.
Corner Lens demonstrates a two-segment light path. Detect the relay before the first target, choose the redirected direction, and apply the same blocking rules to the second segment.
Ambush demonstrates staged effects: selected target, fixed rear circle positions, two warning flashes, one-second charge, and one firing event. Explain why a fired flag is needed while the beam remains visible.


## v63 — Marks, gathering and temporary conversion
Thistlebond introduces `pact_needle`, `gathering_knot` and `change_of_heart` in `scripts/pact_combat.gd`. A traveling needle marks its first hit. A ground-targeted knot warns for 0.45 seconds, then pulls marked enemies with clear paths toward its center. Bosses are immune to the pull. Shared Promise adds four base damage to a converted ally's marked-target attacks after level five.

Conversion removes the hostile through the usual defeat path exactly once, then creates a separate allied body with an eight-second lifetime, independent health and a balanced basic melee or ranged attack. Never leave it in the enemy roster: room doors and wave completion count hostiles, not summons. Do not grant XP again when the allied body expires or dies. Reject bosses, players and training targets before spending cooldown. The host alone resolves damage and expiry; serialized snapshots render the ally and its green ring, health and time label on guests.

Backbeat Sound Wave adds a 25% slow for 1.6 seconds. Triple Tempo uses a unique cast ID and per-target hit tally. Exactly three pulses from that same cast apply burn for 3 damage each second for three seconds. Independent casts cannot combine their hits; each ring can only hit a given target once. Existing status indicators show slow in blue and burn in orange.

Try an exercise: mark two foes, aim a knot between them, then convert a ranged foe. Verify that it helps attack but no longer holds the door shut. Increase its lifetime only in the dedicated conversion module; avoid changing the native enemy death rewards. See `tests/v63_pacts.gd` for regression examples.


## v65 — Provisions and town interactions
Every hero can pack three equipment items plus one automatic food. The food stand explains thresholds and cleanse triggers. Add food via `content/foods/catalog.json`; see FOOD_AUTHORING_GUIDE.md. This is a separate slot, not another equipment key.

Town interactions can have different roles: selecting heroes, trading supplies, route planning, medical recovery and planting a crop. The Seedhouse demonstrates a saved state machine: empty → growing after an eight-gold payment → ready after an adventure clear → empty after harvesting into a free food slot. The Wayfinder demonstrates filtering existing data without reordering the base realm catalogue. Healer respawn preserves the selected hero.


## v66: Hero mastery and portable profiles

Mastery techniques are authored alongside each hero, separately from its passive. Read MASTERY_AUTHORING_GUIDE.md for the JSON schema, supported walking-channel/timed-mine/elemental-tea variations, shared multiplayer support and balanced tuning limits. MASTERY_CATALOG.md lists every title and trade-off. Use the town Profile button to download your work/progress before changing a shared computer.


## Final mastery design task (v68)
Each hero now needs an optional final alternate attack or spell with its own readable graphic. Choose a different ability button from the first mastery technique, explain its advantage and trade-off, and compare both in the training yard. Write the full attack data under `mastery.final_technique.attack`; follow MASTERY_AUTHORING_GUIDE.md. Add a custom SVG/PNG emblem if you wish, or code a new animation pattern with your teacher. Crit milestones are based on successful clears with that hero, not run level. All shipped final alternates are listed in FINAL_MASTERY_CATALOG.md.
