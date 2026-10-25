# V207 — Softer hero artwork, smaller props and clearer attacks

## Visual changes

Young Ram, Crossroads Cat and Living Book have softer coloured edges, gentler highlights and less harsh contrast to fit the existing town and heroes. Their approved colours and identities are retained. Every active pose is neutral/front-facing, including Ram and Cat's primary and secondary attacks. No sprite turning or mirroring.

Each hero keeps the same six-image set: idle, two movement/hover phases, primary, secondary and special. Cached PNG textures keep the same loading/rendering approach. Menu portraits, standard asset paths and opening scenes use the refreshed artwork.

Elder Ram's town landmark canvas is reduced from160×160 to72×72 so he is comparable to nearby characters. His green robe and crook are unchanged; his conversation and town location remain available.

Cat stays small. Living Book is visually22% smaller, floats above a soft shadow, and gently bobs while both resting and moving. Its two movement frames are slow page/bookmark hover phases. Dribble's rendered diameter is reduced from46 to38 pixels while retaining his existing bounce and squash/stretch gait. These size changes do not change hitboxes, speed, reach, collision or stats.

## Held-attack animation fix

Cat's Quick Paws passive reduced the primary interval below the old fixed0.24-second displayed attack pose, so holding attack could keep that image permanently visible. Accepted primary attacks now display a short strike followed by movement/idle recovery, timed against the actual cooldown. This also handles faster item cooldowns. Only the display timing changes: actual attack cadence, damage and effects are unchanged. Matching server snapshots carry the visual strike/recovery timing for other clients. Rejected inputs do not restart the pose.

## Validation and deployment

Native Godot4.5.1 checks cover the pose set, unchanged facing, primary/recovery cycling with passive/haste intervals, network visual timing, accepted solo/arcade casts, Elder size, smaller Book and Dribble, hover/bounce behavior, and imported portrait parity. Native rendered town/combat views are inspected. Existing solo and network-handler regression checks are run. Official character JSON and backend behavior are byte-compared withV206; package hashes/CRCs are verified.

Real-device/browser and live multiplayer playtesting remain. No automatic deployment.

Use the V207 editable project for debugging. Deploy the matching server update to Render first, retaining the existing database, persistent data, environment variables and keys. Then upload the web ZIP to itch.io and hard-refresh. Accounts/saves require no migration.

Test Cat while holding primary and moving in all directions, Ram attacking left and right, Book hovering at rest and during movement, Dribble bouncing, and Elder conversation access.

## Art sources

Built-in image generation edited three six-pose sheets using the V206 designs and supplied existing-hero screenshot as references. Originals: assets/core204/<hero>_soft_source.png. Full prompt set: tools/core204/soft207_prompts.json. Extraction recipe: tools/prepare_soft207_art.py. Slicing metadata: assets/core204/soft207.json. No new art was needed for the Elder/Dribble size adjustments.
