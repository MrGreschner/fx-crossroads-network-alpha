# Crossroads: Realms Beyond — v198.17

Fishing community records now show four top-five boards:
- Largest fish this week
- Largest fish all time
- Rarest fish this week
- Rarest fish all time

Each row shows rank, angler, fish artwork, species, weight and rarity. The boards show each angler’s best eligible catch, with up to five real entries. Smaller screens stack the cards; the record category buttons remain visible while scrolling.

Largest ranks by weight. Rarest ranks by rarity and catalogue catch chance, then species, with weight breaking ties for the same species. Weekly boards reset with the existing Monday week boundary. All-time records persist. Account renames follow the account ID. Authenticated catches are deduplicated against anonymous copies; anonymous historical records remain available without invented usernames. Existing single-champion API fields are retained for compatibility and record notifications.

## Included changes

This is the complete v198.16 update plus the fishing boards. Earlier Lyra Galeforce, Dust Marshal Hogtie, Dustdevil and Veyra projectile fixes, performance improvements, progression guide and teacher/admin features remain included.

## Deployment — manual

1. Upload/deploy Crossroads_v198_17_Server_Update.zip to Render using the existing service and Dockerfile.network. Keep all existing environment variables, database connection, keys and persistent data. Do not create a replacement database or reset it.
2. Confirm /health reports ready: true and build: V198.17-fish-top-five.
3. Upload Crossroads_v198_17_Web.zip to the existing itch.io HTML5 game, replacing its web build.
4. The editable project is Crossroads_v198_17_Editable.zip.

The server automatically adds a profile-to-account lookup table and fish lookup index using idempotent schema updates. No account, save, existing record, database or key is deleted/reset. No production database was accessed during this update. Deploy the server first so the client can retrieve full lists; old servers retain champion fallback and show an update notice.

## Validation

- 29 fish-board server checks using real PostgreSQL-compatible SQL and authenticated HTTP: ranking, weekly rollover, duplicates, multiple devices, renames, account visibility, privacy, legacy fallback and data preservation.
- 37 existing records server checks and 444 fishing catalogue checks.
- 38 native Godot UI checks: four top-five lists, artwork, weights, empty/malformed data, older server fallback, fixed navigation and 1440/960/620/390 widths.
- 55 existing records menu checks.
- Packed runtime UI checks and clean server startup/health smoke check (see bundled validation logs).

Real-device playtesting remains. The production database and deployment have not been changed.
