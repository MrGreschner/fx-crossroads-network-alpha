# Crossroads: Realms Beyond — v198.29 • Quarantine Nightwatch

Build: `V198.29-quarantine-nightwatch`. Full release based on v198.28; includes all earlier marina, fishing, teaching, arena and realm work.

## Realm population and progression

- **Moonveil Masquerade (Medium):** increased authored defenders from 13 to 64. Mixed groups of all five native enemy types now occupy the ballrooms, galleries, side passages and courtyards. Positions avoid fountains, walls and the merchant. Actual solo combat XP reaches level 10 before the Marquis rather than arriving around level 4.
- **Hollow Quarantine (Challenging):** retained the midpoint Quarantine Warden and added a separate hidden **Lockdown Aberration** encounter farther east. This new creature has six original animated art poses, a containment-tank silhouette and a multi-attack kit. It reveals as a living player approaches, with an announcement and initial reaction delay. Its defeat does not complete the realm.
- Fixed the Warden's missing defeat count and changed Quarantine's final-boss eligibility to inspect remaining original defenders. Summons and converted enemies do not block completion. Clearing the map now leads to one final Director and a usable exit.
- **Plague Director:** now a named final boss, with 1,500 HP, pursuit movement, needle fans, targeted lobs and a warned area pulse. His attack cycle accelerates below half health.
- **Cinderheart Citadel (Hard):** increased defenders from 40 to 56, spread across the four sectors. The five successive boss encounters now have 650 / 820 / 1,000 / 1,500 / 2,600 HP. Existing heat fields, fire pools, lethal rivers and telegraphed boss hazards remain active.
- Moonveil and Quarantine co-op now use the full authored populations and a single correct final boss after the map is cleared. The final defeat completes the match instead of starting unrelated repeat waves.

## Game Dev access and voyage darkness

- Active Game Dev preview grants the Deep Sea Rod and existing fishing equipment, maximum fishing/gardening progression, seed supplies, test funds and Waylight test supplies. Realm access remains unrestricted. These are temporary preview changes: checks confirm the real profile file remains unchanged, including after launching the ocean.
- Lake and ocean night darkness now cover the full viewport with a cached, softened lantern mask, independent of anchor state. Dawn and dusk fade gradually; resizing the screen preserves darkness coverage. A night-visibility message appears in the voyage status bar. This hardens the reported anchor/night issue; real-device reproduction testing is still recommended.

## Validation

**8,686 automated checks passed:** 79 Quarantine/Game Dev/night checks, 218 realm balance/completion checks, 6,018 Citadel/fishing/voyage regressions and 2,371 Between/co-op regressions. These run using the packaged runtime resources. Checks include real attack/XP progression, boss movement and attacks, solo exits, two-player co-op completion, spawn walkability, preview save isolation and anchor/night behavior. Logs are in the editable project.

The final archives also pass ZIP integrity, baseline-file preservation, source/server/web agreement and a clean local Render-style server import/health boot. Native test exits retain existing resource-cleanup warnings. Automated checks validate mechanics and progression; student playtesting on actual browsers/devices is still needed to tune difficulty and performance.

## Manual deployment

No production service or database was modified. Upload **Crossroads_v198_29_Server_Update.zip to Render first**, then **Crossroads_v198_29_Web.zip to itch.io**. Keep the current database URL, keys, environment variables and persistent storage. No database migration or account reset is needed. **Crossroads_v198_29_Editable.zip** contains the full editable project and validation logs.
