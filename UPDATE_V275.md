# Crossroads V275 — enemy motion candidate

This is a complete saved-source candidate built from the verified V274 source and V274 Web/Server packages. It is NOT a fully playtested release. GDScript syntax, artwork, source-preservation and package checks passed; native Godot and browser gameplay were NOT run in this workspace because the executables were unavailable and downloads were blocked. V274 remains the last previously runtime-validated release. Nothing has been deployed.

## What changed

The V270 neutral-body fix had suppressed pose selection, forcing 137 shared creatures to use idle even while walking or attacking. V275 uses distinct frontal idle, movement A, movement B and attack drawings again. Facing stays independent from travel and attack direction: no direction-indexed frames, body mirroring or movement-driven body rotation.

24 recent creatures have new simpler sheets following the user's Bramble/Thorn Archer/Hollow Imp reference: soft coloured contours, coarse pixel clusters, restrained matte shades, readable midtones and much less surface detail. The requested first10 have six poses (idle, move A, move B, primary, secondary, special); the additional14 have four poses, with the single attack reused for other attack keys. The runtime atlas is80px per cell with binary transparency and no translucent surrounding haze. All original generated sheets, exact prompts and the user reference are included in tools/release275.

- Sunfield: Solstice Cantor (internal sunbeam_cantor) steps on alternating boots; Saffron Hopper cycles its insect legs through compression/takeoff and a smooth visible hop. Regular and crowned Sun Sentinels also have moving frontal parts and attack poses.
- Frostbound: Frostling, Ice Archer, Glacier Hound and Cryowarden have distinct limb/paw/boot poses; Snow Oracle has separate hover-part poses.
- Confluence: Divided Heart (confluence_heart) and Glass Mender hover with moving parts; Sluice Crab has changing articulated legs; Coil Slinger (coil_singer) compresses then springs upward.
- Folded Coast: Cartographer pages, Inkfin/Foldwing wings and Crease Sentry fins animate while keeping paper/ink identity and frontal faces.
- Moonburrow: Burrowfang, Shardspitter, Fusehare, Rootwarden, Echo Bat, Sap Nurse and Flintroot have frontal locomotion/attack poses. Existing emergence, sinking, dirt and trails remain; new limb motion replaces the extra body bob. Fusehare hops.

113 earlier shared atlas creatures keep their own earlier art and have their existing four distinct frames re-enabled. Legacy pose selection also receives the requested walk/attack key instead of forced idle. Quest actors Briar Bandit, Glowcap Slinger, Rootbound Keeper and Summit Golem use their four-pose quest cast atlas in those realms. The all-enemy audit also records older legacy sources, stationary Vitality Geode and custom Descent routes; the Descent gait/strike renderers were not redesigned.

## Frostbound snow and ice

The four rectangular slippery overlays have been removed from the displayed terrain. Existing snow/ice materials now form rounded shores, snow islands, safe merchant snow and winding snow crossings. The exact binary CPU classification map used to compose the terrain pages also controls the shared solo/co-op slippery query. Ice-textured areas slide; snow clears momentum and gives grip. The existing steering, speed cap, stun handling and collision code are unchanged. A two-world-unit shoreline pixel and subpixel visual edge blending are the only transition precision limits. Old slip_patches metadata is retained for historical compatibility but no longer queried or drawn by the active Frostbound path.

This changes which ground is slippery, as requested. No leaderboard/time-record migration or progress reset was performed.

## Preservation and checks

All hero art, hero animation code, enemy identities/health/damage/skills, authoritative navigation/collision, spawn/campaign data, saves, quests, shops, network protocol and database schema remain unchanged. Only existing enemy presentation adapters/draw calls, the ice surface query, and release/export metadata changed. The new atlas adds approximately3.69MB of decoded RGBA; the two replacement ground pages have the same pixel dimensions as before, plus a CPU classification mask. This is not a school-device performance benchmark.

Static validation includes GDScript parsing, all137 shared sets having four different nonempty image frames, binary atlas transparency, unchanged original source files and gameplay-method boundaries, unchanged distance-gait sampler and momentum mechanics, and representative snow/ice samples. Source/Web/Server changed runtime files match byte-for-byte; all packed entries and ZIP CRCs are checked. These checks do not substitute for Godot type checking or playing the Web build. Full native/browser regression results from earlier releases must not be attributed to V275.

## Files and reconstruction

Extract BOTH Editable parts into the SAME parent directory. They form one complete standalone Crossroads_Realms_Beyond source tree, including prior art, tools and handoffs. RecoveryDelta is optional and only applies over BOTH complete V274 source parts; it is not standalone. The early Working_Recovery is superseded by the final candidate files.

The Web and Server_Update ZIPs are candidate packages for the existing itch.io/Render workflows. They have not been uploaded/deployed to production. The animation GIF and self-contained Animation_Review.html use the actual normalized sprite atlas, but are artwork previews, not game captures. The surface PNG is a terrain preview.

Before treating V275 as production-ready, open the source in Godot4.5.1 and let imports finish; run qa/v275_motion_check.gd, then play Sunfield, Frostbound, Confluence, Folded Coast and Moonburrow in solo and co-op. Check travel/attack poses, snow entry/exit momentum, obstacle edges, the merchant and realm completion. Existing QA tests that assert every action texture equals idle describe the superseded V270 freeze and intentionally no longer apply.

Protect the final complete V275 candidate source, V274 rollback, all still-required older source/base/patch dependencies, all original art/prompt/style/handoff notes and the active SUBVEIL source/Site/latest Windows package. Never infer a successfully saved version from chat text alone. Consult the live DEVELOPMENT_RECOVERY_HUB.md for the confirmed Library IDs and latest validation status.
