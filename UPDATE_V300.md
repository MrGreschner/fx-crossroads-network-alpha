# Crossroads V300 — The Between: realm remnants

The Between now reuses updated textures and scenery from21main progression realms, versus the previous six visual themes. All expert/extreme environments are explicitly excluded at the user's request: Astral Rift, Chimevault, Ebonwake and Shattered Oath. Their normal realms elsewhere in the game remain intact.

The13entry-pool environments are The Whispering Grove, The Ember Quarry, Honeyglass Gardens, Firstbell Elementary, Sunfield Expanse, Frostbound Rink, Confluence Foundry, Petalbrook Canopy, The Clockwork Orchard, Crossbell Middle School, Neon Crucible, Cinderheart Citadel, Crossroads High. Ring8 adds Folded Coast, Moonburrow, Moonveil, Silverfall and Brasslock (18total). Ring10 adds the quarantine and Lantern Marsh environments (20total). Ring12 adds Orbital Breach (21total);ring14 retains that same permitted pool. This broad visual variety is deliberately separate from existing combat families and unlock rules. A given random seed need not contain every permitted environment.

Only presentation changes:168reused scenery slots,42edge-matched floor/route materials,21water surfaces and21pond masks. Original realm art is sampled/cropped with preserved sprite proportions,front-facing artwork and foot registration;no paid or new image-generation work. All original assets are untouched. Provenance records exact source files, SHA256, crop regions and normalization. Small normalized libraries avoid loading all of the original full-size realm atlases. Cache capped at21libraries;only visible chunks/props draw. No decorative merchant carts were added.

Each deterministic2x2visual cluster keeps a coherent realm identity, with matching paths, raised boundary detail, varied scenery and fishing water. Floors draw before all globally sorted raised scenery, preventing adjacent chunks from painting over props. Raised props fade near heroes, including co-op players. Original fog-of-war and minimap remain. Solo and co-op HUDs identify the visible realm remnant.

## Gameplay and compatibility

The existing seeded maze layout, exits, parent links, collision/open checks, forms, fishing pool/spot positions, six combat families, enemies/guardians, minion caps, pursuers, rewards, banking, extraction, cooldowns, profile schema, snapshots, save/resume and multiplayer authority are unchanged. Every existing non-drawing function in waylight_expedition.gd is byte-identical;only draw_ground changed there. The environment choice uses a separate seeded RNG and never consumes gameplay RNG. Existing saved expeditions receive the new visuals without relocating routes, enemies or deposits. No layout-version bump, migration, reset or new encounter roster.

The six existing Attunement seal encounters retain their original guardians and mechanics. Their visual areas use Grove, Quarry, Silverfall, Frostbound, Lantern Marsh and Orbital scenery respectively;the last no longer pulls expert Astral Rift environment art. This update excludes expert/extreme environments;it does not redesign the existing Attunement encounters.

V299's Dawnstone Keeper/FirstSteps and all21Descent boss/midboss ranged-pressure fixes remain intact. Sovereign Depths retained. Nothing deployed,deleted or reset;SUBVEIL untouched.

## Verification and limits

Exact21363-file saved V299 source restored from allfourV278Editableparts + finalV293RecoveryDelta + finalV299RecoveryPatch before editing, and every file hash verified.

Godot4.6.3:13622native checks cover old/new layout equality, walkability and return routes, fishing preservation, deterministic coherent visual clusters, all21eligible environments, expert/extreme exclusions, Warden visual identities and bounded material/prop loading.131actual host/guest co-op checks cover streaming, separated-player chunk union, authority, attacks, pickup idempotence, fog/shared-haul snapshots, extraction and identical visual selection.169Attunement regression checks pass with fixture clock advanced between replays to respect the pre-existing24hour cooldown. The untouched V175 test initially failed five obsolete immediate-replay expectations; its cooldown-aware copy passes, with no production cooldown changes.

SoftwareOpenGL renderer:77checks and27captures:4actual solo scenes with original fog,21explicitly labelled unfogged environment fixtures,2controlled network-client scenes. Rendering preserves saved state. Fixture-only setup errors (sample seed persistence, uninitialized client enemy pool/health and leftover placeholder foes) were corrected before final passing run. Existing ObjectDB/three-resource shutdown warnings persist. These are not browser playtests, remote multiplayer sessions, human maze playthroughs or classroom hardware performance benchmarks.

Targetengine4.5.1 retained. Web/Server incrementally rebuilt from verified V299packages,not fresh4.5.1exports. Source/PCK/Server runtime bytes match. ZIP CRC/SHA, source recovery reconstruction and exact streamed PCK reconstruction verified. The real Godot JS wrapper/reassembly check uses a WASMstub;full browser/itchpreview stillpending. Web keeps the V298 itch packaging fix, with every extracted file below200MB and total below500MB.

## Restore / upload

Editable restore: extract ALL FOUR V278Editableparts, then finalV293RecoveryDelta(libfile_9849168108cc8191a7cd3aa1602a2814), then finalV300RecoveryPatch. This patch is cumulative294–300 over EXACT finalV293 and includes V298 itch packaging plus V299 fixes. Do not overlay older294–299patches afterward. Patch alone is NOT standalone. Open Crossroads_Realms_Beyond/project.godot. Keep V299 as rollback and retain every base dependency.

Deploy matching V300Server_Update through the established GitHub/Render workflow, preserving environment variables,secrets,database and persistent storage. Then upload the ENTIRE V300Web ZIP to the existing itch.io HTMLgame page and mark it playable in browser. ZIP itself may exceed200MB;individual extracted files are below the limit. Check itch preview/login/solo/co-op. No live deployment was performed here.

Next visual queue: Oldwater Lake → Coastal Voyage → Wayfarer Wilds → Mistglass Rift. Challenge Hall building was updated earlier, but its five challenge maps still need a dedicated art pass. Do not silently advance those in this release.
