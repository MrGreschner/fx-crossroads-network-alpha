# Crossroads V227 — five realm creature-art refresh and Expert access

23 older enemy/boss designs now use soft coloured contours, restrained matte shading and readable neutral poses matching the V207/V208 direction. Each has four transparent 64x64 runtime frames: idle, movement A, movement B and attack. Flying, plant, quadruped, object and machine designs retain their individual movement styles.

| Realm | Refreshed designs |
|---|---|
| Honeyglass Gardens | Queen Mellifera, Honey Beetle, Seed Blossom, Amber Hornet, Royal Nectar Nurse |
| Firstbell Elementary | The Last Bus, Pencil Scrapper, Backpack Biter, Paper Sprite, Lesson Warden, Recess Ringleader |
| Sunfield Expanse | Sun Sentinel, Solstice Cantor, Saffron Hopper; already refreshed Bramble and Thorn Archer retained |
| Frostbound Rink | Frostling, Ice Archer, Glacier Hound, Snow Oracle, Cryowarden |
| Confluence Foundry | The Divided Heart, Sluice Crab, Coil Singer, Glass Mender |

Glacier Hound has a front-facing quadrupedal pose set so movement does not imply running backwards. Display rectangles preserve each old species' visible height and stable ground/hover anchors, with space for contained attack art. This scaling is visual only. Runtime uses small imported textures and cached visual factors; no new full-screen shaders, particle systems or per-frame image processing.

Cast poses are linked to existing attack events through the existing shared animation timestamp. Co-op previously discarded that timestamp when receiving enemy snapshots; it now retains it. The actual co-op Frostbound Rink boss now explicitly selects Cryowarden's loaded sprite set, preserving its existing health/attack logic.

## Expert progression

Three distinct Hard realm clears unlock Crossroads High, as before. Clearing Crossroads High unlocks Astral Rift, Chimevault and Ebonwake. Four other Hard clears alone no longer bypass High. Portal/lobby hints say “Clear Crossroads High first”; solo/co-op entry uses the same shared rule. Existing legitimate clears and Game Dev access remain available. No progress/records were reset.

## Verification
609 focused art/import, solo/co-op loader, attack timestamp, actual co-op boss spawn, visual sizing and unlock checks passed. 4,574 shared hero/portrait/stat/authority/Cave checks also passed. Native Godot idle/attack galleries and motion frames inspected. Gallery sprites are enlarged for inspection, not a claim of actual relative world scale. No full browser play test or real-device frame-rate measurement is claimed. PCK resource hashes, ZIP CRCs, release checksums and browser PCK byte count verified. Combat definitions and authored maps remain unchanged.

## Install
Manual server first, then itch.io Web. Editable project supplied separately. Nothing deployed. Preserve all accounts, database, saves, records, secrets and environment variables. No migration/reset included. All V226 changes, including Lyra and the fixed opening camera, are retained.
