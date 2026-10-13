# v79 — Multiplayer entry fix and movement heroes

## Multiplayer startup
Arena hazards were bound to their game only when starting an arena match, although Defence and Descent also called their movement, update and draw helpers. The nil `game.mode` access now has both an unconditional scene binding and safe guards for an unbound/freed owner. Fresh Defence/Descent solo scenes and fresh co-op/arena host scenes are exercised independently so starting Arena first cannot conceal this bug.

The second screenshot showed a dependent preload failure. The packaged scripts now import and run together cleanly. Extract this ZIP into a fresh folder, stop any paused Godot session, then open that folder's project.godot instead of mixing scripts from older versions.

## Burrowick
- Smooth 1.3s digging cycle, dipping underground and rising like a reverse bounce; base speed 205 and a modest ±20% cadence rather than a rapid slide/stop.
- Fully buried movement remains immune; stopping and attacking expose the hero.
- Pop-up Pounce stays a quick direct dive and now reaches 560, twice its previous range.
- Four visible, numbered trail sections show exactly which paths Cave In will collapse. The newest in-progress segment counts toward that limit. Crossing hostile enemies are slowed 20%; trail contact checks are throttled.

## Nullweaver
A dashed triangle, crosshair and SPECIAL AIM label show the exact default-special footprint before casting. The alternate special previews its three burst circles instead. Works with mouse or touch-stick aim.

## Molten Pilgrim — lava snail
165 health, 75 movement speed, dodge distance 28% of normal. Shellbound is its main travel tool.
- Furnace Breath: narrow 54-damage lava burst; burn plus lava patches.
- Shellbound: an aimed, visible 0.8s lob up to 460. Lands for 32 damage and leaves lava; remains vulnerable while airborne. Walls stop travel.
- Backdraft Volcano: six seconds of random lava balls erupting from its shell, leaving lava where they land.
- Melting Presence: level-5 aura removes up to 40 percentage points of nearby enemies' damage reduction (60% becomes 20%). Cannot strip allies, stack with another snail, bypass invulnerability or raise damage against an unprotected foe.
- First mastery: 600-range lob with lower impact damage.
- Final mastery: Caldera Crown replaces the moving volcano with a warned lava ring.

Overlapping ground patches from one snail share a damage limit. Patch/projectile counts are bounded and old patches expire.

## Kite Corsair — momentum glider
100 health, up to 280 normal gliding speed. Builds speed, banks gradually and brakes when movement is released.
- Sail Needle: 18-damage wind dart, gaining up to 12 damage from actual gliding speed. A blue gauge shows momentum.
- Windlass Swing: hook a wind anchor and swing along a curved path, hitting each touched enemy once.
- Storm Delivery: three visibly parachuting parcels burst with staggered warnings, push foes away and leave wind pads that speed allies.
- Updraft Reserve: level-5 protection for two seconds after a swing.
- First mastery: longer swing for reduced contact damage.
- Final mastery: Headwind Harpoon replaces momentum needles with slower shots that pull and slow enemies.

Both heroes include complete pixel-art poses, distinct two-word names, titles, crit milestones, mastery choices and multiplayer effects. ABILITY_CATALOG.md documents the new options for student projects.

## Validation and installation
Godot 4.5.1 import, dedicated hero/multiplayer checks, independent entry-mode checks, and native rendered views cover the crash paths, movement, damage, aura arithmetic, friendly fire, patch limits, expiry, targeting and mastery alternatives. Regression checks cover the previous heroes, lobby/arena configuration and recovery. Live multiplayer on the school's devices remains the final deployment check.

This archive is editable source. Export a new Web ZIP for itch.io; do not upload the source ZIP as the playable build. Render still uses the version-14 room service already included in v77/v78; no additional setting change is introduced here. Windows build scripts now label their output v79.
