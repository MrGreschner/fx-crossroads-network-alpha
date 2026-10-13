# v13 — Phone layout and Silverfall Reach

Includes all v12 content and public matchmaking. No Render service changes are needed for this version. Export a new Web build from this project and replace the ZIP on itch.io. All players should refresh to the new build.

## Phone layout
The viewport now expands to the available aspect ratio instead of adding the game's fixed 16:9 side bars. The camera and terrain rendering use the actual viewport size. Touch sticks and action buttons follow the bottom and right edges, while menus and their touch selection areas remain centered together. Menu touch text is larger; multiplayer health/ability information moves above the movement stick. Item information and minimaps use the available space. Rotation and resize rebuild the controls and release held inputs. Portrait shows a landscape reminder.

The Web preset explicitly uses Adaptive canvas resizing. This fills the space itch.io supplies; it cannot remove Safari's toolbar or change the parent itch.io page size. Enable itch.io's mobile-friendly and fullscreen options where available. Landscape is the intended phone orientation. The update has been checked in Godot at wide viewport sizes; a physical iPhone/Safari check is still needed after exporting.

## Silverfall Reach
A 7,600 × 3,800 river realm with long waterfalls, willows, three river crossings and alternating bridge routes. River banks are impassable except at the bridges. There are 48 enemies across four banks:
- Cascade Herons: ranged water shots and a bird silhouette.
- Sluice Beetles: sturdy, slow melee enemies with carved shells.
- Ripple Eels: fast, fragile serpentine pursuers.

The Crowned Torrent appears after clearing the solo realm (stage three in co-op). It alternates three warning-marked attacks: parallel water lanes, targeted geyser pools, and a close surge that calls an eel. Summons are capped at three live eels. Boss base health is 950; co-op adds 55% per additional player. Warnings give roughly 1.2 seconds to move or dodge.

## New free hero: Reed, the Ferryman
An otter traveler with an oar, belonging to Silverfall and available in Character Hall and every multiplayer mode.
- 115 HP; speed 235.
- Oar Sweep: 25 damage, 82 reach, 0.65-second cooldown.
- Skipping Stones: three 12-damage shots, 390 reach, 3.5-second cooldown. All three must hit to deal the full 36.
- Riverward: 60% damage reduction for 2.5 seconds, 12-second cooldown.
- Rivercraft: the existing 10% guard passive from level five.

Uses existing shared attack styles and unlock levels to preserve solo/multiplayer parity. No immunity, infinite healing or uncapped summons.

## Student editing
New content lives in content/characters/ferryman.json, content/regions/silverfall.json, the four content/enemies JSON files, and scenes/realms/silverfall.tscn. Original sprites and terrain are in assets. tools/build_silverfall.py regenerates this expansion's assets and content without replacing other student creations. Bridge collision coordinates are in realm_trials.gd; update those too if moving the bridge paint.

## Checks
Godot headless checks cover registry loading, solo enemies, impassable water, open bridges, the unique boss, all three special attacks, capped summon behavior, viewport size, touch-button bounds, centered menus, and co-op realm/boss setup. Run:
`godot --headless --path . --script tests/v13_mobile_silverfall.gd`
