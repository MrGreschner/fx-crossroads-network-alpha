# Crossroads V259 — Character Hall, Deepwell, realm merchants and Descent detail

Complete update based on the authoritative V258.1 files. Nothing deployed. Open the Editable project with Godot 4.5.1.

## Changes

Character Hall list portraits grow from a 36px to an 80px viewing envelope; rows are taller and long captions trim safely. The selected hero has a 192px square viewing stage instead of 48×56. Grid tiles grow to 120×152 with 108px portrait space. The shared portrait generator, neutral poses, relative body sizes, records portraits and hero gameplay dimensions are unchanged. A short hero stays short; the viewing controls provide more room for detail.

The misplaced Deepwell street lamp at (-780,760), which crossed the Exchange sign, is removed from both drawing and light collection. Two tall facade posts become compact wall lanterns at the same glass/light origins. Window glow, the Exchange footprint, door (-815,825), mine entrance, rail route, services and nearby street lighting remain intact. Day and night previews are included.

All existing realm merchant kiosks use the newly painted red-roofed timber design with cream plaster, a service counter, shelves, bottles and supplies. The common draw path covers 24 authored realm merchant anchors. The 25th authored realm has no merchant service; none was added. The existing 96×80 drawing rectangle, service coordinates, 95px interaction radius, E interaction, stock and prices remain unchanged. Custom realm scenery, including Sunfield's caravan, remains in place. A single 288×240 cached PNG renders each visible kiosk.

Ten milestone bosses, ten mid-bosses and the lava guardian now recover detail directly from their existing painted source sheets. The old shared atlas sampled these large creatures at only about 38–54 visible pixels tall. All 84 poses are re-baked at four times the previous sampling resolution per dimension, on 320px stages. This is source recovery, not enlargement of the reduced bitmap. Every pose uses the same normalized body bounds and foot position; existing world heights, offsets, identity, colour, attack pose selection, HP, collision, attacks, dodging events and progression remain unchanged. The Wick-Eater comparison and all-guardian contact sheet show the result.

Action notices reserve explicit text height so the dialogue body cannot collapse inside its scroll area. Empty bodies are suppressed. Multiplayer notices now expire locally after six seconds in every mode; identical repeated network snapshots do not restart the timer. A new message appears normally. Notices age while menus cover them and can be dismissed with ×. Solo dialogue retains its existing source timer and can also be dismissed. Generic Descent messages are headed CAVE DESCENT, rather than an unexplained NOTICE. Existing interaction cards remain available.

## Verification

- 533 focused native assertions and the same 533 WebGL2 assertions pass, with 19 browser captures.
- Retested Descent combat: 4350 assertions. Portrait/cosmetic/marina/UI regression: 4450. All-realm portal regression: 451. Training Yard exit regression: 24.
- Total current native assertions: 9808. Current browser checks contain no page, script or parse errors.
- All original source files are retained; 19201 original files remain byte-identical and ten existing runtime/configuration files change. All campaign/content JSON, scenes and navigation data remain byte-identical. Changed runtime bytes match Editable, Web PCK and Server Update.
- Actual E input opens the Grove merchant. All 24 merchant anchors are exercised and all 25 authored realms launch. All 84 guardian poses are nonempty, cached, and checked against their old normalized bounds. Desktop, smaller desktop and compact dialogue layouts fit the viewport. Timed notices, new notices, identical snapshots, empty messages and dismissal are checked, including every multiplayer mode.
- Native software OpenGL and browser software WebGL2 were used. These checks freeze combat for visual inspection; they are not a human playthrough or a benchmark on a school Chromebook. Native shutdown retains the inherited ObjectDB/three-resource warnings; no script/parse failures remain. Screenshot readback may produce a browser GPU-stall diagnostic.

## Efficiency and preservation

Guardian strips load lazily, with at most three retained strips and twelve AtlasTexture wrappers: 4,915,200 decoded RGBA bytes (4.69 MiB). The merchant texture adds 276,480 decoded bytes (0.26 MiB). Both use existing draw calls and pose timing. No new lights, particle systems, shaders, physics, per-frame image processing or network messages are added. Portrait controls reuse existing cached textures. Record state, currencies, rewards, hero stats, enemy definitions, services and protocol are unchanged. Report policy remains 3 and network protocol remains 11. V258.1's ordinary Training Yard walk-out exit remains intact. No new record reset or database migration.

## Packages and installation

Apply Server Update before Web. Keep the server's secrets/runtime configuration and all user/database data. Preserve Web's cross-origin isolation headers. Neither package has been deployed.

Editable is a complete `.tar.gz` Godot project. Extract and open `Crossroads_Realms_Beyond/project.godot`. Original art sources and the full new merchant source are inside it. Previews includes native and browser screens, the Wick-Eater before/after comparison and the 21-guardian sheet. The Integrity file records archive checks and hashes.

## Continuation

Use this V259 Editable as the next authoritative base. `scripts/descent_detail259.gd` owns the bounded high-detail guardian texture cache; `cast_art232.gd` delegates guardian texture requests but preserves its draw geometry. `merchant_art259.gd` is the cached kiosk loader and `game.gd` routes the shared merchant draw. `hero_hall.gd`/`hero_grid.gd` own the larger UI envelopes. `action_notice250.gd` owns notice layout/lifetime. `town_calendar.gd` and `town_props240.gd` hold the Deepwell lamp correction. Assets and provenance are in `assets/detail259`; tests/evidence in `qa`; reproducible tools in `tools/release259`.

Build scripts expect the authoritative extracted V258.1 under `Crossroads_Realms_Beyond`, old Web/Server under `web258`/`server258`, candidate under `project259/Crossroads_Realms_Beyond`, and the merchant original at `base258/Pixel-Art Potion Merchant Kiosk.png`. Re-running the historical integration script on an already integrated project is not supported. Build a fresh uniquely named fixture for concurrent tests; never overwrite a mounted PCK. QA fixtures are excluded from production PCK. Source-only QA/tools remain in Editable.
