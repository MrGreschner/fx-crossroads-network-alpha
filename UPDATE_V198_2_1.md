# Crossroads v198.2.1 — dashboard repair

This is a server-only follow-up to v198.2. Keep using the current v198.2 itch.io web build. The multiplayer build remains V198.2-moving-primaries and protocol 11.

## What was found
The existing reports page maps every report-query exception to the same “Database unavailable” message. Live public health reports the database modules initialized, but this does not prove authenticated dashboard queries are currently working. We cannot confirm the exact live exception without the authenticated response or logs.

Local reproduction confirmed that a historical non-numeric player-count value can break the match-list query. Activity summary queries can also fail when casting decimal numeric counters directly to integers. These are confirmed failure paths; they are not confirmed as the cause on the live database.

## Changes
- Both dashboard backends read JSON measurements defensively: numeric values within the supported bounds are retained; malformed, non-numeric and out-of-range measurements are omitted from calculations. The original records are not edited or deleted.
- FPS averages exclude observations with unreadable FPS instead of counting them as zero.
- Activity summaries accept decimal-valued low-FPS counters without failing an integer cast.
- Failed dashboard requests now display a specific error code and an explanation. Server logs record only the route and code, excluding SQL text, raw error messages, connection strings, passwords and report values.
- No account, save, key, schema, gameplay or database migration changes.

## Deploy on Render
1. Extract Crossroads_v198_2_1_Server_Update.zip. It contains the complete server runtime, with files at the archive root.
2. Upload/commit the extracted files into your EXISTING server repository/project root, preserving the folder structure. Keep Dockerfile.network as the existing Render Dockerfile path.
3. Deploy the latest commit on the existing Render web service.
4. Keep the existing database, persistent disk and all existing environment values and keys. No reset or new database is needed.
5. Once deployment finishes, refresh https://fx-crossroads-network-alpha.onrender.com/reports with Ctrl+F5 and sign in as teacher with your existing password.
6. If data still fails to load, copy the new red error including its code. This provides the missing evidence needed for the live issue. Do not share database passwords or connection strings.

No itch.io upload is required.

## Error-code guide
- 57014 or TIMEOUT: report query exceeded its time limit.
- 42703, 42P01 or 42883: report query and database fields/tables/functions do not match.
- 42501: database user lacks permission.
- 22xxx: unreadable stored value.
- 08xxx, ECONNREFUSED, ECONNRESET, ENOTFOUND, ETIMEDOUT, EAI_AGAIN, 57P01/2/3: connection or database availability problem.
- UNKNOWN: an unclassified failure; server-side investigation is still required.

## Validation
- Original malformed-record failure reproduced locally with PostgreSQL-compatible PGlite: SQLSTATE 22P02.
- 74 targeted integration checks passed for historical records, both report and activity dashboards, 1/7/30-day filters, exports, valid statistics, record preservation, safe error codes, credential exclusion, authentication and recovery after a transient query error.
- All 106 existing dashboard integration checks passed.
- All existing Godot/gameplay/account source and dependency lockfiles remain unchanged from v198.2. New server helper is included in the complete runtime archive.
- Live authenticated dashboard success is not yet verified. Deployment remains manual.
