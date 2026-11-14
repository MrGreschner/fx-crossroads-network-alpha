# Crossroads V240 — town materials, walking and Studio

Dust Marshal now alternates left and right steps with a stable front-facing upper body. Only his two walking frames changed; all other 496 pose frames and 79 portraits are pixel-identical to V239.

The Pixel Studio Design lesson button now opens above the editor. Lesson navigation remains within the same viewport, and dismissing it preserves unsaved artwork.

Cave Descent has a new hand-shaped slate entrance matching the updated mine. Its existing interaction and animated eyes remain. Cliffside Cottage below it moves down 100 world units, together with its door, collision, home route and connecting path.

Both town fountains, street lamp posts and Deepwell Exchange now use soft coloured contours and matte storybook shading. Fountain streams and ripples remain animated. Street lamp glass matches the existing light-source position; Exchange windows and posts light at night. Deepwell retains its interaction, railway connection and footprint.

Four new prop textures share one cached 1024 × 512 atlas; no per-frame image processing was added. Original generated art, prompts and a rebuild tool are included in Editable.

Validation: 70 focused checks, 23 Leech Charm regression checks and 15 Cave Descent loadout regression checks passed (108 total). Native compatibility-renderer previews reviewed for day/night cave, Exchange, fountains and Studio lesson overlay. The test fixture reports retained references at shutdown; no in-session script errors occurred. Browser/device playtesting remains recommended.

Deploy Server_Update first, then replace Web. This package has not been deployed. No database migration or record reset. Previous performance work, Cave Descent loadouts and the 8 HP-per-KO Leech Charm are retained.
