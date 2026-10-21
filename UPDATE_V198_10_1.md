# Crossroads v198.10.1 — Folded Coast boss movement

Build V198.10.1-coast-boss · protocol 11 · Godot 4.5.1
Complete update based on v198.10, including the leaderboard refresh/gardening improvements and all accepted v198.9 fish, consumable-slot, shop-price and potion changes.

## What was fixed

The Cartographer's ink, paper fans and folds ran in its dedicated Folded Coast script, but Folded Coast was omitted from the shared realm boss-movement update. The boss could attack while missing its regular pursuit/strafe movement and relying on small stalled-boss recovery nudges. Folded Coast now participates in the normal boss update; the Cartographer's data also declares its 100-unit movement speed.

Fold destinations remain the existing three authored landing spots. The boss now prefers a different spot within pursuit distance of the player, so a fold does not strand it at the far end of its island. The existing warning remains visible before landing. Health, attack damage, ink, paper fans, attack timing and stun/slow rules are retained.

## Other realms checked

An automated motion audit exercised all 24 official portal realms in solo and authoritative co-op, with 45 boss forms/stages per route: **90 encounter cases, 492 checks passed**. This includes school mid-bosses and final exams, all four Neon Crucible bodies, the Chimevault guardians and the Gilded Usurper generations. The audit measures movement from each authored encounter area with a live nearby target, checks walkable ground, and uses each realm's own AI/spawn setup. No other stationary-boss defect appeared in these cases.

Folded Coast received a longer 32-second simulation in each route, checking immediate pursuit, repeated folds, ink and projectile attacks, stun handling and landing coverage across its boss island. The same 90-case audit passed against the updated web PCK. The records/gardening HTTP checks (27) and records server/database checks (41) also passed.

These are automated encounter checks, not a complete manual playthrough of every quest/procedural expedition or physical-device playtest. Normal attack windups, burrowing, stun and scripted pauses are allowed; bosses do not ignore their mechanics just to keep moving.

See BOSS_MOVEMENT_CHECK_V198_10_1.md for the per-realm results. Editable source includes detailed JSON/log evidence.

## Deploy this complete build

1. Update the source behind the existing Render service using Crossroads_v198_10_1_Server_Update.zip and deploy it.
2. Preserve the existing PostgreSQL database, accounts, cloud saves, environment variables, encryption keys and signing secrets. No reset or manual migration is needed.
3. After deployment, https://fx-crossroads-network-alpha.onrender.com/health should report build **V198.10.1-coast-boss**.
4. Upload the contents of Crossroads_v198_10_1_Web.zip to the existing itch.io HTML5 game, then refresh the browser.
5. Keep Crossroads_v198_10_1_Editable.zip as the full editable project.

Render first, then itch.io. No production deployment or database mutation was performed automatically. This package contains the previous pending records and gardening update, so one server update and one web upload cover everything.
