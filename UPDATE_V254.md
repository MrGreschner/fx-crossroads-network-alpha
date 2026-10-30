# Crossroads V254 — Ember Quarry and a denser Whispering Grove

Completed 29 October 2026, based on authoritative V253. Nothing has been deployed.

## Ember Quarry (realm 2)

New cooled basalt/ash ground, compacted stone trail, softened trail edges, craggy boulders, copper/ember ore and decorative mine carts. The existing rail route has matte dark rails and restrained steel highlights. The authored Quarry scene, its points, obstacles, encounters and travel route remain byte-for-byte unchanged.

The Quarry guardian now has charcoal basalt skin, copper stone features, obsidian horns and ember-orange eyes. Idle, two walking poses and attack windup are independently painted. The main guardian, its two smaller split forms and the Quarry encounter-journal portrait all use the new identity. Grove's guardian keeps its original appearance. Original visible idle height and foot anchor determine fitting; existing gameplay dimensions are retained. Health (620), fireball behaviour, split trigger and fragment health (240 each), damage and rewards are unchanged. No new enemy ID or save migration.

## Whispering Grove

459 additional solid trees raise the count from 127 to 586 (over 4.6 times as many), with a mix of broadleaf and conifer silhouettes. All 127 original obstacle markers remain unchanged. New trunks have a 32px collision radius; authored path centrelines keep a 235px planting exclusion, with larger protected service/encounter pads including the boss clearing.

An independent 24px navigation-grid flood fill with 20px player padding confirms all 31 route, encounter and service targets remain reachable. The 459 new trees intentionally add collision in previously open forest areas, while keeping the main route, spawn, merchant and boss access open. Both solo and co-op load all 586 obstacles from the same authored scene. No fishing spot has been added.

## Efficiency and preservation

Both tree silhouettes share one GPU atlas; scene markers become ordinary obstacle dictionaries rather than separately animated tree nodes. Existing spatial collision indexing, view culling and retained 512px terrain chunks remain active, with a 48-chunk limit. New scenery is static and cached, with no new lights, shaders or per-tree particle effects. Exported Quarry images have about 1.96 MiB of RGBA payload in total (including unused standalone authoring inputs); actual textures load lazily. This excludes driver and existing game overhead. Actual school computers were not benchmarked.

Outside the new Grove tree markers and scoped rendering adapters, original gameplay content is preserved. The full V252 aquatic update, town, other realms, heroes, items, Descent, services, currencies, drops and saved profile schemas are retained.

## Verification

44,608 passing assertions: Grove/Quarry 171, aquatic 35637, Descent 4350, marina/UI 4450. New checks exercise both realms, retained caches, solo/co-op geometry, actual main-boss spawning/splitting, distinct cached boss poses, journal identity and server script compilation. Independent forest-navigation validation covers 31 targets.

13 native previews and 13 WebGL2 previews cover dense Grove scenery, Quarry locations, low-light stress tests, main/split guardians, identity/pose comparison and both co-op environments. The normal production browser menu also opened successfully. Low_Light is a synthetic visibility tint, not a new realm day/night mechanic. Some preview fixtures remove enemies or reposition the player/camera to expose artwork; the boss previews use the real solo spawning and split methods.

Every changed production resource was byte-compared across source, Server Update and Web PCK. Unchanged Web resources were preserved. All ZIPs pass CRC and duplicate-path checks. Native isolated QA retains the baseline ObjectDB/three-resource shutdown warning; local browser startup can report unavailable external-service fetches. No live server deployment, shared-backend write or multi-device network test was performed.

## Downloads and continuing development

- Web: complete browser build; retain the existing HTTP(S) isolation-header configuration.
- Server Update: back up and stop the existing server, overlay the update while retaining existing secrets, runtime configuration and user data, import with Godot 4.5.1 as required, then restart normally. Apply Server before Web. The matching pair is important because Grove now has additional solid trunks.
- Editable: standalone Godot 4.5.1 project. Allow editor import to finish. Layout markers remain authorable; runtime adapters supply the upgraded images.
- Previews: all native/browser captures.
- Art Sources: seven full-resolution original generated images, exact prompt records and reference inputs. Built-in image generation produced the art. Technical normalization and atlas packing preserve transparent margins and foot alignment.

Use V254 as the next base. `scripts/quarry_art254.gd` owns the shared tree atlas, Quarry textures and guardian frames. `scripts/grove_art253.gd` samples each realm's real base terrain when finding path edges. `scenes/realms/grove.tscn` contains all original markers plus the appended DenseTree nodes. `tools/release254` contains the build, normalization and navigation-validation tools. Preservation builds require V253 Editable under out253/deliverables, extracted project253/web253/server253 and the current project254. To reproduce normalization, extract Art Sources content into sources254 and run prep254.py; it can use the included prompts.json when art254 job records are absent.
