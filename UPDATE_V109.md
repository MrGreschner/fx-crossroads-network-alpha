# v109 — Town improvements and Twisterspell

## Town
- Moved the upgraded flower garden and bench away from the Food Stand sign; moved the free-bread table into its own space.
- Rebuilt the Fellowship Pavilion as an open timber meeting hall with a roof plaque, lanterns and a communal table. Its footprint and interaction point match the art.
- Rebuilt the Relay Workshop with supply benches, crates, chimney and framed windows. Moved it south of Squirrel Post, with its own approach path and readable sign.
- Rebuilt the Watermill with detailed timber framing and an animated paddle wheel over the river, including water splashes. Its sign stays on the building.
- Added Mistglass Spire beside the Training Yard and the river. Interact to learn the weather controls, test Twisterspell or open Character Hall.
- Added Ramguard Barracks near the arena district, with flags, a ram archer, soldiers and Captain Hornby's gold crest. Guards patrol the courtyard.
- Added entrance paths and collision footprints. Checked the town with all projects built, as in Game Dev mode.

## Hero 75: Twisterspell
A cheerful female weather apprentice in a lavender hat, with four matching sprite poses and a staff holding river mist.
- Primary — Pocket Twister: hold LMB / Aim-Fire to charge; release to launch. Quick taps cast small funnels. Power caps after 1.6 seconds; fully charged funnels gain a gentle inward pull. Damage: 3–6 every 0.5 seconds, with 30% slow. At most four funnels per caster; 4.2-second lifetime.
- Secondary — Whirlaway: controllable tornado form for 3 seconds, 55% faster movement, 7 contact damage every 0.5 seconds and slow. No invulnerability.
- Passive — Patient Forecast: primary funnels last one extra second.
- Special — Hail, Please!: 2-second stationary channel, then 12 randomly placed hailstones over 3.6 seconds. Landing warnings last 0.7 seconds. Each impact deals 16 damage and stuns foes for 0.6 seconds.
- First mastery — Wide Forecast: two wider, lighter funnels instead of four compact ones.
- Final mastery — Sleet Stitch: a shorter channel launches a directed corridor of heavier ice and longer slow, replacing random hail and stun.

Weather effects have finite lifetimes and count caps. Allies are excluded from damage, slow and pull. Obstacles clip their movement. Only the host owns charge timing and damage; snapshots carry visual state. Entering town clears weather effects. Pull updates run at a bounded cadence to limit combat work.

## Student files
ABILITY_CATALOG.md explains the reusable weather styles and parameters. Both mastery catalogues now list all 75 heroes. tools/build_mastery_catalogs.py regenerates the tables from the current character files.

## Validation
Godot 4.5.1: v109 weather and town tests passed (tap/hold/release, damage growth, pull, funnel cap, team protection, network snapshot round trip, guest authority, movement/channel locking, delayed hail, normal solo input, town cleanup, entry collision and native tower interaction). v107 PvP minion and v108 training regression tests passed. Rendered and inspected the town, mage and Character Hall at 1280 x 720. ZIP CRC and full extraction verified. Native/Web exports and live multiplayer over Render were not run here.

## Publish
1. Extract the editable ZIP into a fresh folder and open FX_Crossroads/project.godot.
2. Export the Web preset and replace itch.io's browser upload with that exported Web ZIP.
3. For the Windows download, use BUILD_WINDOWS.cmd; upload exports/FX_Crossroads_Windows_v109.zip separately as a Windows download. See WINDOWS_BUILD_GUIDE.md.
4. No Render redeployment or settings changes are required.
