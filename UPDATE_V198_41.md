# Crossroads V198.41 — Workspace access, record cleanup and damage eligibility

Cumulative update from V198.40. Deploy the server first, then the web build, using the existing Render service, database and keys.

## Changes

- Removed the Learning Academy shortcut from the main menu. Student and teacher menu access remains available.
- Fixed the teacher workspace's `Origin rejected` login error. The account endpoint now accepts sign-in requests from its own website, using the same explicit-origin rules as the education endpoint. Untrusted and lookalike sites remain rejected; authentication and teacher-role checks are preserved.
- Repairing a confirmed Solo or Co-op time now includes its matching weekly/all-time and combined-list copies. Equal-valued results attributed to a different official hero or the other route are preserved. The repair checks that selected rows are absent before reporting success.
- Routine cloud auto-saves no longer invalidate an otherwise unchanged record preview. Repairs still lock the account, validate selected record values and preserve the newest unrelated progress.
- The repair page has readable realm names, route labels and clock times, plus a specific button for MVP's three owner-reported custom-hero results.
- Fixed a shared Studio rendering error for custom multiplayer heroes found during regression testing.
- Damage is checked where it is awarded, independently of the global run marker. Custom heroes and unofficial mixed parties cannot add personal damage, weekly cosmetic damage, rolling crown damage or uploaded damage totals. Official and approved public community heroes still count.
- Known historic personal damage explicitly recorded under `custom_` hero IDs is preserved in an unranked archive and removed from personal lifetime damage, once only. Official hero damage is preserved. Damage uploads use eligible per-hero totals; a declared unrestricted lifetime total cannot override that ledger. The server requires the updated eligibility policy, so update the client after deploying the server.

## Deploy

1. Deploy **Crossroads_v198_41_Server_Update.zip** to the existing Render service. Keep DATABASE_URL, CLOUD_SAVE_KEY, REPORT_SIGNING_SECRET, REPORT_ADMIN_PASSWORD and other existing environment settings. No replacement database or account reset is needed.
2. Confirm `/health` shows **V198.41-records-and-access**.
3. Upload **Crossroads_v198_41_Web.zip** to the existing itch.io game. Refresh the game page.
4. The teacher workspace is https://fx-crossroads-network-alpha.onrender.com/education/teacher. Sign in with the teacher's game account; this is separate from the private administrator login.

## Finish MVP's cleanup

The live service was checked read-only during this work. It still reported V198.40, with the screenshot times in both solo weekly and all-time boards. No live records were changed here.

After deploying V198.41:

1. Open https://fx-crossroads-network-alpha.onrender.com/records/admin and use the existing private administrator login.
2. Enter **MVP** and click **Preview records**.
3. Click **Repair MVP’s three reported realm times** and confirm. This targets only:
   - The Whispering Grove — 0:37.60 (stored 37.6020933333326 seconds)
   - The Ember Quarry — 0:51.57 (stored 51.5714148888878 seconds)
   - Honeyglass Gardens — 1:35.60 (stored 95.609895999999 seconds)
4. The result reports the verified number of matching copies removed. In the unchanged test fixture, these three results had twelve copies across solo/combined and weekly/all-time lists. The live count may differ if some copies were already removed.
5. Refresh Community records in the game. Have MVP **load the repaired cloud save** to update the personal records on his device.

The preset matches this username, these exact results within a tiny numeric tolerance, the solo route and missing hero attribution reported in the screenshots. It does not reset other users, other MVP results, Descent records, inventory, creations or accounts. The repair stores recoverable board and encrypted cloud-save backups. The existing restore safeguards remain.

Already-uploaded historical damage and weekly buckets with no per-hero attribution cannot be reconstructed from a speed-record screenshot. Those server high-water totals are not blindly reset. They require an authenticated evidence-based correction if contaminated. This update prevents new custom damage and excludes known local custom contributions from future lifetime uploads; it does not claim to have repaired unattributable historical network damage.

## Verification

- 27 native eligibility/menu/damage checks passed, including direct custom damage with no run marker, one-time old custom-damage archival, and official/approved-community damage.
- 17 access/cleanup checks passed using isolated PostgreSQL/PGlite, including same-origin teacher sign-in through cookie exchange, untrusted-origin rejection, ledger validation, duplicate cleanup and restore.
- 37 existing database record/repair checks passed under the new policy.
- Browser teacher login passed using actual form submission, session handoff and workspace loading.
- Browser repair workflow passed, including the MVP preset removing all twelve matching copies while preserving unrelated damage rows.
- Dedicated multiplayer regression and packaged-resource results are in VALIDATION_V198_41.md.

Real-device playtesting, production deployment and the authenticated live MVP repair remain to be performed. Records remain client-reported; this is not a complete anti-cheat system for arbitrarily modified clients.
