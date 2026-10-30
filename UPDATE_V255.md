# Crossroads V255 — Honeyglass Gardens

Completed 29 October 2026, using the completed V254 as base. Packaged and verified; nothing deployed.

## Artwork and presentation

Eight painted assets update the garden turf, honeycomb amber-glass floor, grand trees, giant flowers, honey lamps, garden fountains, glass pavilion and raised flower beds. Soft coloured edges, matte shading and clear pixel clusters continue the V207/V208 style. Existing mint/amber architecture, rounded trees, pink/lavender/apricot blossoms and Queen Mellifera's identity are retained. Pool banks have subtle irregular shapes, lilies and restrained ripples; small flower clusters use the painted blossom art. The Crown seal is now an amber-brass and mint lattice. Room labels have a dark outline for readability.

Six props use one 1024×256 shared atlas with original texture dimensions, visible-alpha fitting and bottom anchors. Two 128×128 floor tiles use retained polygon draw commands and world-aligned UVs. All 26 floor layers plus one background are created once; no per-frame texture generation, new shaders, particles or lights. Existing view culling and nearby-player foliage/giant-flower fading remain in place. Ground borders follow authored polygons. Connecting glass corridors retain their open visual joins. Original collision radii, marker positions, prop scale, entrances and route geometry are unchanged.

## Preservation and verification

The Honeyglass campaign JSON, region JSON and scene are byte-for-byte unchanged, including 26 connected floor pieces, 69 props, patrols, three discoveries, checkpoints, spawn, Crown gate and Queen chamber. No enemies, rewards, damage, Queen health (640), attacks, unlocks, services, NPC routes or save schemas changed. All V252 aquatic artwork and V253/V254 Grove/Quarry improvements are retained.

47,820 passing assertions: V255 3212, prior Grove/Quarry 171, aquatic 35637, Descent 4350, marina/UI 4450. Tests cover real patrol and Queen spawning, original gate transition, checkpoint/discovery/boss navigation, collision stability during rendering, co-op geometry/art, cached texture reuse, retained layers and server script compilation.

Before/after navigation comparison sampled 29,025 positions at each gate stage (58,050 total). Standability hashes and 54 route results match exactly. 19,060 existing Editable files are byte-preserved, with all original files present. Every changed runtime resource matches across Editable, Server Update and Web PCK; unchanged Web resources remain identical. ZIP CRC and duplicate-path checks passed.

Eleven native and eleven WebGL2 previews cover the approach, Vestibule, Nursery, Orchard, giant-blossom garden, Crown Chamber, pavilion, nectar pools, low light, actual Queen with attack warning and co-op garden. The production browser menu opened successfully. Low_Light_Visibility is a synthetic stress-test tint, not a new realm day/night mechanic. Scenery previews reposition the player and remove enemies to expose art; the Queen view uses the actual spawning method and an existing warning.

School hardware was not benchmarked. The new runtime-loaded atlas and floor tiles total 1,179,648 bytes (~1.13 MiB) of uncompressed RGBA payload, excluding existing assets/driver overhead. Native QA retains the inherited ObjectDB/three-resource shutdown warning. Local browser startup may report unavailable external services; final QA has no script/parse/page/WebGL errors. No live backend, multi-device network test or deployment was performed. `qa/evidence255/render_budget.json` records before/after software-renderer draw counts; these are observational preview counts rather than timing benchmarks. The more detailed art has a modest draw-call cost, while floor primitive counts fall and floor/texture allocation remains bounded.

## Packages and continuing

- Web: full browser build. Retain existing HTTP(S) isolation headers. Apply Server Update before Web.
- Server Update: stop/back up the server, overlay while preserving secrets, runtime configuration and user data, import with Godot 4.5.1 as needed, then restart normally.
- Editable: standalone Godot 4.5.1 project; allow import to finish. Layout markers remain editable. New art is scoped to Honeyglass and does not replace shared assets used by other realms.
- Previews: native/browser screenshots and paired before/after comparisons.
- Art Sources: eight full-resolution built-in image-generation originals, exact prompts and hashes. `prep255.py` performs technical fitting and atlas packing; full-resolution originals are not needed at runtime.

Use V255 as the next base. `scripts/honeyglass_art255.gd` owns the cached art and floor presentation. `scripts/immersive_worlds.gd` selects it only for Honeyglass. Production resources live in `assets/honeyglass255`. `tools/release255` includes preparation, preservation-build, preview, browser and packaging helpers. Rebuilding expects baseline V254 ZIPs in `base254`, extracted `web254`/`server254`, and candidate `project255/Crossroads_Realms_Beyond`. Art preparation accepts `sources255/prompts.json` when transient job files are absent.
