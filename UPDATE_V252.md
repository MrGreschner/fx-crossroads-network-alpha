# Crossroads: Realms Beyond — V252 Living Waters

Completed 29 October 2026. Authoritative base: the complete V251 Editable, Server Update and Web packages. No deployment has been performed.

## Artwork

All 239 catchable species now use the upgraded soft coloured edges, matte shading and readable pixel clusters of the accepted V207/V208 style. Each species has three separately painted individuals (717 sprites), with differing markings, tones and subtle proportions. Fish, rays, sharks, eels, crabs, crayfish, lobsters, shrimp, prawns, squid, cuttlefish, nautilus, jellyfish, mussels, seahorses, sea slugs, newts and tadpoles are covered. Legendary, Mystical and Fabled species retain their own designs and receive richer organic crests, scales, shells, fins and restrained luminous details.

The final visual review corrected the Cobalt Moray, Cataract Grayling, Ironclaw River Crab, Lantern Marsh Crab, Vaultshell Crab and Blue Shore Squid silhouettes, and strengthened the Moonspotted Char and Deepglass Cisco legendary finish. All ten catalogue boards were visually reviewed.

## Implementation and preservation

An existing catch ID deterministically selects one of the three specimens. An old catch retains the same appearance after saving, loading and old-weight reconciliation; its appearance also matches its community record when a catch ID is available. Species-only previews use specimen zero. No save migration or network schema change is needed. Missing identities use the canonical specimen.

The artwork is integrated into catch reveals, kept collections, species journals, details, aquarium tanks, favourites/player cards, the dashboard, sales/storage, voyage cargo/storage, aquarium income, community records, weekly previews and existing fish jumps. The aquarium still uses the existing mass-to-area scale; its crop follows each specimen's actual painted bounds.

All original fishing content, species IDs, rarities (83 Common, 43 Uncommon, 51 Rare, 17 Very rare, 27 Legendary, 13 Mystical and 5 Fabled), catch odds, weight/length distributions, trophy rules, rewards, equipment, services, routes, collisions and geography are unchanged. V251 Descent, reward and prior artwork changes are retained. Original SVGs remain as editable historical references. Runtime changes are limited to the artwork adapter, its display consumers, the release/version stamps and export inclusion.

## Efficiency

Runtime sprites are 192 × 108 transparent PNGs, with no new particles, lights, shaders, physics or per-frame pixel readback. Three individuals are alternate catches, not cycling animation frames. A lazy 48-entry private texture cache holds at most 3,981,312 bytes of uncompressed RGBA payload, plus texture/object overhead; UI elements can retain additional textures. An entire 239-species canonical journal has about 18.9 MiB of RGBA payload. Headless catch rolling does not decode artwork. Original full-resolution strips stay outside Web, Server Update and Editable. Actual school hardware was not benchmarked.

## Verification

129,958 passing assertions across 12 suites, each run against both source and packaged resources. These include 35,637 aquatic checks in each mode, plus the retained Descent, marina/UI, decoy/studio, actor, town/crop, items, streets, shops, loadout, healing and realm-finale suites. All 717 sprite hashes are distinct; every species, transparency margin, crop, mass scaling, stable variant, cache bound and roll independence check passed. Final source and packaged aquatic runs are full runs, not partial runs.

12 native previews and 12 WebGL browser previews cover the three artwork galleries, daytime/nighttime catch displays, kept collection, species journal, details, aquarium, player card, sales and community records. The normal production Web menu also opened successfully without the preview fixture. The fresh Godot 4.5.1 server editor import completed without script or parse errors. Every changed runtime resource was byte-compared across source, Web PCK and Server Update; unchanged Web resources were preserved.

Isolated native QA shutdown retains the baseline ObjectDB/three-resource cleanup warning. No script/parse failure occurred in the passing runs, and browser validation reported no script/page errors. Expected fetch warnings occurred for unavailable external services in the local offline test. No live shared backend, public host or multi-device session was tested or deployed.

## Packages and use

- Crossroads_v252_Web.zip: complete browser build. Serve over HTTP(S) using the existing isolation-header setup; do not open index.html as a local file.
- Crossroads_v252_Server_Update.zip: complete server project update. Back up the existing server, stop it, overlay the update while retaining existing secrets, user data and runtime configuration, import with Godot 4.5.1 if required, and restart using the existing server command. Update Server before Web.
- Crossroads_v252_Editable.zip: standalone Godot 4.5.1 project, with the 717 runtime sprites, manifest, source adapter and reproduction/QA scripts. Open project.godot and allow import to finish.
- Crossroads_v252_Art_Sources.zip: all 239 full-resolution transparent original strips, prompt specifications, provenance, style and per-species references, and the runtime manifest. The 37 recovered final strips have reconstructed production specifications rather than claimed exact original prompts; the remaining and final-correction prompts are recorded. Built-in image generation produced the artwork.
- Crossroads_v252_Previews.zip: all-species contact sheets, final anatomy review, native/browser screenshots and historical review media. Historical PNG/GIF evidence from qa/evidence248, 249 and 250 was relocated here with original paths and SHA256 values so Editable stays below 512 MiB. Game files were not removed.
- Crossroads_v252_Package_Integrity.json: ZIP sizes, SHA256 values, CRC and duplicate-path verification.

## Continuing development

Use V252 Editable as the next authoritative project, with matching V252 Web/Server packages. `scripts/fish_art252.gd` selects and caches specimen art. `assets/fishing252/manifest.json` supplies all 717 painted bounds/areas and source hashes. `tools/prepare_fishing252.py OUTPUT ART_SOURCES` normalizes the original strips; it needs Pillow, NumPy and SciPy. Clear an unchanged source's manifest entry if deliberately changing normalization parameters, because identical source hashes reuse verified output. Keep source originals in the separate Art Sources folder and preserve catch IDs. Release tools under tools/release252 require the V251 baseline packages when reproducing the archive-preservation build.
