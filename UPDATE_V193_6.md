# Crossroads v193.6 — cloud card and community records fix

## Uploads

Upload Crossroads_v193_6_Web.zip to the existing itch.io game.

The Server_Update ZIP updates four matching files in the existing GitHub server repository. Preserve the folder paths, replace these files, commit and deploy the existing Render service:

- network_service/community.mjs
- network_service/named-records.mjs
- network_service/release.mjs
- network/release.gd

Keep all other repository files and Render environment settings, including CLOUD_SAVE_KEY and DATABASE_URL. This is an update, not a replacement repository. Existing accounts and encrypted cloud saves are retained. Deploying restarts active multiplayer matches. If v193.5 was skipped, this patch includes its server fixes too.

## Changes

- Compact clickable player card beside account details, above Save now. Click or tap to enlarge; Close player card returns to the save screen. Narrow screens stack the preview above the controls.
- Resync my records is now a separate gold-outlined action above the categories, with a busy state.
- Fixed authenticated records uploads returning 503 because a database parameter inferred an integer type for timestamps containing fractional seconds. Regression test reproduces the failure at .123 seconds before the explicit timestamp cast and passes afterward.
- Removed the city name from the community reset message. The reset schedule itself is unchanged.
- Includes v193.5 fish rarity labels, weight dials, journal trophy backfill, named-record tie fixes, immediate board cache invalidation and username heading.

After deploying both updates, sign in and load your cloud profile, then open Community Records and press Resync my records. Wait for upload success and the refreshed board. Keep a downloaded profile backup until save/load has been checked.

Validation includes Godot layout and public-wording checks; browser compact/expanded card and records UI checks; local PostgreSQL-compatible account/community tests with fractional timestamps and rolling damage; existing profile-core checks. No production account or database mutations and no deployment were performed by these tests.
