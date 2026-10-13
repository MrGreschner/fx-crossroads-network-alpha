# v50 — Worlds with routes, rooms and discoveries

Includes every v49 feature, 34 free heroes and 23 regular realms, plus the separate Wayfarer quest expedition.

- **Honeyglass Gardens:** wildflower arrival, a connected branching glass honeycomb maze, rooms with defenders, a giant-blossom garden and a sealed Crown Chamber for Queen Mellifera. Clear the defenders to open the seal.
- **Sunfield Expanse:** a narrow tree-lined approach with few enemies leads into terraced fields. Tall grass draws over heroes and enemies; a small faded gap keeps your own position readable. New **Solstice Cantors** warn for 1.3s before calling down large sunbeams. The beams last 4s, deal 16 player damage per second and heal enemies for 9 HP per second, capped at maximum health. Leaving the beam avoids subsequent ticks.
- **Lantern Marsh:** impassable black water surrounds raised islands, boardwalks and a muddy alternate route. Mud multiplies walking speed by 55%; leaving it immediately restores normal terrain speed. Pulsing spore pools, drooping moss trees, reeds, a forgotten shrine and optional caches/springs reward exploration.
- **Silverfall Reach:** expanded to 10,500 × 7,600, with connected alternate routes, enormous trees, animated waterfall streaks/foam, elevated bridges, three enterable treehouses with interiors and discoveries, and Moonwater Lake. E / mobile Interact boards the raft; a 1.2s boarding window lets allies join. The raft smoothly carries the party, then releases them on the far bank. Interact at either jetty to call an empty raft. A walking route remains available. Treehouse entry/exit and rewards use the same Interact button.
- **Pippa Fernwhisker:** a female red panda ribbon-weaver from **Petalbrook Canopy**, a new Medium realm of forked ribbon paths, hollow-log passages, an enterable cottage and ribbon workshop, tea nooks and a sealed maypole arena. Petal Duckers side-step and weave volleys; Briar Tails telegraph rushes; Nectar Keepers heal their defenders. **Bloomtail Regent** mixes rushes, delayed root patches and radial weaving petals.

## Pippa's kit

Primary **Ribbon Stitch** sends two visible intertwined ribbons: 15 damage each, 0.8s cooldown, 380 reach; each ribbon hits each target once. Walls stop them. Secondary **Fern Double** plants a leaf decoy for 3s (8s cooldown). Nearby ordinary enemies chase the decoy; bosses resist it. When it blooms, allies within 150 receive 8 HP. It never heals enemy players. Special **Maypole Waltz** sends three ribbon tips spiralling outward to 230 over 2.4s; each tip can hit each foe once for 36 damage and 2s slow (18s cooldown). Passive **Afterglow**, unlocked at level 5, grants allies healed by the double 20% speed for 2s.

## Progress and co-op

These five realms use authored routes and defenders, rather than the generic three-wave co-op format. Trail milestones unlock minimum level 3 (secondary) and level 5 (passive) for the party; reaching the guardian guarantees level 6 (special). These milestones do not grant an automatic heal. The guardian appears after their defenders fall; defeating it unlocks an accessible Interact exit. Optional discoveries grant gold or environmental healing once per player and are not required for victory. Environmental healing does not inflate ability-healing contributions. The route arrow uses navigable waypoints. All damage, rewards, gates, decoys and raft motion are host-owned and included in snapshots.

The raft prevents walking/dodging/casting while aboard; player sprites remain visible. Guest movement packets cannot override transport. Four players can ride together. New-run reset clears all temporary world and hero state. Effects are bounded and grass/props are culled to the camera; objective paths are cached.

## Validation and install

Godot 4.5.1 import/parse, v50 world/hero assertions, v50 co-op snapshot assertions, and existing v49 robot, v48 heroes, v44 school co-op and v38 gate guards passed. Actual Compatibility-renderer previews were inspected for all five worlds, including grass, flowers, moss, raft and Pippa's special. Physical phone browsers and a live internet multiplayer session have not been exercised here.

Open `project.godot`, export a **fresh Web build**, zip the Web export files with `index.html` at the archive root, and replace the itch.io game upload. This download is the editable Godot project, not a ready-to-upload Web export. No Render command/environment changes are required.

Student references: `IMMERSIVE_REALMS_AUTHORING.md`, `ABILITY_CATALOG.md`, `STUDENT_GUIDE.md`. `tools/build_v50_worlds.py` reproduces these original maps and pixel assets; running it overwrites v50 content edits, so change its source before regenerating.
