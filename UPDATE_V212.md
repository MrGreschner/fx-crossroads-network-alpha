# Crossroads: Realms Beyond — V212

## Modest hero polish
Refreshes Sunpetal, Snowdrift, Veyra Spellthief, Backbeat, Harbor Bell, Polarity, Pippa Fernwhisker, Spindle, Patch, Bracken of Moonburrow, Prism Mage, Aurel, Rune Duelist, Garrick Runebearer and Nera Lockstep.

Uses the V207/V208 direction: coarse square-pixel clusters, matte shading, selective coloured contours and restrained palettes. Distinct species, outfits and signature props are retained. Six 80×80 transparent poses per hero: idle, movement A, movement B, primary, secondary, special. Neutral front-facing movement works across travel directions. Projectiles remain drawn by the existing aimed combat effects.

Lyra Galeweaver receives the requested more confident expression and cropped-top outfit. Diamond Scout has a smaller head/cap in relation to his body, retaining his baseball uniform and skin tone.

## Runtime and editing
Small frames are cached. Large original sheets are retained in the editable project, excluded from the web runtime and server bundle. The portable tools/prepare_hero212_art.py rebuilds frames from originals (requires Pillow and NumPy). Crossroads_Hero_Art_Style_V212.md contains the full reusable art prompt.

Combat balance, controls, accepted-action recovery, hero statistics, Cave Descent, saves, account data and persistence code are unchanged from V211. Existing portrait scale adjustments for Dribble and Living Book remain.

## Validation
1,851 automated art, action replication, stat, layout, import and cave appearance checks passed, plus 16 networking checks. Native visual checks cover the refreshed portraits, comparison, compact Hall and town. Dedicated authority startup is checked. The test fixture retains the pre-existing resource-in-use warnings on teardown. Browser and real-device playtesting remain.

## Deployment
Deploy Crossroads_v212_Server_Update.zip to Render first, then Crossroads_v212_Web.zip to itch.io. Crossroads_v212_Editable.zip contains the editable project and original art sheets. No live deployment has been performed. Preserve existing accounts, database, saves, environment variables and keys.
