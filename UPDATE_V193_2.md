# v193.2 — temporary profile-core server release

## Purpose and actual feature removal

This release removes the browser account-control console and administrator password-recovery feature while preserving player signup, login, session authentication, encrypted cloud saves, revision-conflict protection, ten-save history retention, and the existing database. This is a temporary reduction in functionality, not an attempt to conceal or rename flagged scripts. No files are encoded or password-protected, and no antivirus settings are changed.

The accounts.html and accounts-control.js files are absent. Their serving route and file-reading code are removed. Account console URLs and administrator recovery/reset requests return HTTP 503 with a clear unavailable message. The reports page explains that the console is unavailable. Player recovery-answer setup and authenticated player password changes remain supported. Authenticated administrative role/disable/history/restore APIs retain their existing protection, but there is no browser interface for them in this release.

## What changed between v191 and v193

V192 introduced nine-character minimum passwords, fictional recovery answers and their hashes, guarded administrator password resets, the new recovery UI, additional reserved usernames, and individual-species trophy records. It also fixed realm selection/ordering, realm access progression, and the lobby-to-town transition. V193 did not change the account files; its main server addition was the community hero submission/review/catalog service and the matching gameplay validation. The initial v193.1 rebuild rewrote the account UI and separated the web loader's files; Defender still blocked the server download reported by the user.

## Tonight's deployment

This is SERVER ONLY. Keep the v193.1 Web ZIP that passed your Defender check. Protocol 11 and report schema 3 are unchanged. Client V193.1-preview and server V193.2-profile-core labels differ intentionally so reports identify this reduced release.

1. Download and scan this server ZIP with Defender enabled. If it is blocked, leave it quarantined and stop. Do not restore/allow it or change security exclusions.
2. If the ZIP passes, back up the database, then extract it into the existing GitHub server repository. Delete network_service/accounts.html and network_service/accounts-control.js from that repository as well: dragging new files into GitHub does not delete old ones. Update the changed accounts.mjs, reports.html and release files along with the complete package.
3. Keep DATABASE_URL, CLOUD_SAVE_KEY, administrator credentials and all other current Render environment variables. Do not generate a new encryption key or create another database.
4. Deploy that commit on the existing Render service. Confirm build V193.2-profile-core, then test signup/login and a cloud save. Do not migrate existing progression blindly: download the player's local profile first, then sign up or sign in and follow the existing conflict-safe import flow.
5. Confirm that progress returns after logout/login before wider use. Browser-based role assignment and administrator password resets are unavailable in this reduced release. Do not promise students password recovery until the complete console is restored.

## Limits

This package has not received an antivirus clearance or Microsoft determination. Removing a feature may narrow the detection source but does not prove the remaining package is safe. Only use it if Defender permits it; the Microsoft review of the exact blocked archives remains appropriate. No production deployment or database operation was performed by the assistant.

## Verification completed

35 profile-core integration checks passed using a local PostgreSQL-compatible test database. These include registration, login, save/load, encrypted persistence, stale revision rejection, logout/session rejection, password changes, history retention/restoration, and unavailable console endpoints. The 40-check community hero API regression also passed with the actual Godot validator. Archive integrity, required-file presence, removal of the console files, and the new server manifest were checked. No live accounts or live database were used. Antivirus clearance is still unconfirmed.
