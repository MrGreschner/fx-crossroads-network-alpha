# v188 — Cloud accounts, named records and hero support

## Deploy in this order

1. Download a player profile from every device that still has progress. Keep those ZIPs.
2. Keep the existing PostgreSQL database and signing secret. **Check the database itself is on a persistent paid plan with recovery/backups before students rely on cloud saves.** Paying for the game web service does not upgrade the database. Render Free Postgres expires after 30 days and has no managed backups: https://render.com/docs/free and https://render.com/docs/postgresql-backups . Do not replace or reset the existing database.
3. In the Render game web service's Environment settings, add **CLOUD_SAVE_KEY**: 32 cryptographically random bytes encoded as base64. Generate it privately using `node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"` or `openssl rand -base64 32`. Keep a secure offline copy. Never put it in GitHub, the web ZIP or a student profile. Losing/changing this key makes existing encrypted profiles and school codes unreadable. DATABASE_URL, REPORT_SIGNING_SECRET and REPORT_ADMIN_PASSWORD stay as configured.
4. Replace the service files using **Crossroads_v188_Server.zip**, commit to the existing GitHub repository and deploy Render. New tables are additive and created automatically. `/health` should report `V188-preview` and `accounts.ready: true`. Combat can remain available if accounts are unconfigured; account screens show the setup error rather than pretending a save succeeded.
5. Upload **Crossroads_v188_Web.zip** to the current itch.io game as the HTML ZIP. `index.html` is at its root. Leave the current page URL intact.
6. On two devices, create a test account, migrate a backed-up local profile, save, sign out, and load it on the second device. Verify the hero, fish, gardening, currencies and mine before enrolling the class. An older simultaneously open device must receive a save conflict rather than overwrite the newer save.

The editable Godot project is **Crossroads_v188_Editable.zip**. No live GitHub, Render or itch.io deployment was performed here. This build uses protocol 11 and report schema 3.

## First sign-in and migration

Main menu → **CLOUD ACCOUNT**, or Profile footer → **Cloud account**.

- Create a public game username and a password of your choice. Usernames are 3–20 ASCII letters/numbers/underscores, start with a letter and are unique without regard to case. The form says not to use real names, to keep names appropriate and not to reuse school passwords. Passwords are 15–128 characters; registration asks for confirmation.
- An account starts with no cloud save. Choose **Keep this device's progress** to migrate your existing local profile, or explicitly start a fresh one. Merely signing in never uploads an empty local profile.
- For an existing account, explicitly load the cloud profile. If this device has an unsent local copy belonging to that account at the same cloud revision, it offers a local recovery choice. A newer remote revision cannot be overwritten silently.
- Successful loading backs up the previous local profile and restores gameplay progress, portable creative work and supported drafts. School permission flags and local teacher-class administration are excluded from the cloud profile.
- Saves are automatic every 60 seconds while signed in, with a prompt save shortly after returning to town and a Save now button. Saving also works from multiplayer scenes. The screen displays the last successful cloud revision or an error. A freeze may still lose activity since the last successful save.
- Sign out saves first, then restores the local guest profile. Do not close a shared school computer while signed in. Sessions are memory-only, expire after 12 hours and must be signed into again after refreshing; passwords/tokens never travel in downloaded profiles.
- A 409 revision conflict pauses saving. Download this device's profile before choosing the newer cloud copy. Offline/expired sessions keep local progress and show an error; reconnect/sign in to reconcile explicitly.
- Cloud snapshots are limited to **4 MB of JSON**. Very large recordings/portfolios may exceed this; the game reports the limit and retains the previous cloud snapshot. Full downloadable player ZIP backups remain available. Large creative media still needs exported backups.

## Private account controls

Open the existing private reports dashboard and choose **Account controls**, or visit `/accounts` on the same service. It uses the existing private administrator credentials (`teacher` + REPORT_ADMIN_PASSWORD). A Teacher game account does not grant server administration.

Search usernames, select an account and assign **Player**, **Student** or **Teacher**. The next sign-in for a Student/Teacher asks privately for the first five letters of their last name (all letters if shorter), plus their first initial. These are encrypted separately, shown only in the protected account controls and never added to public records or telemetry. Roles grant Academy access without changing game progress. Existing local role unlock codes do not change signed-in account roles.

Controls also disable/enable an account, reset a forgotten password after checking the student in person, list ten recent cloud revisions and restore one. Restore creates a new revision, signs out devices and records an audit entry. No email or full legal name is collected at registration. Passwords cannot be viewed.

Passwords use salted scrypt (N=131072, r=8, p=1); cloud saves and school identification use AES-256-GCM with CLOUD_SAVE_KEY. Random bearer sessions are stored only as hashes on the server. Parameterized SQL, origin checks, request-size/concurrency limits and sign-in throttling are included. These choices follow https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html . Username checks normalize separators, repeated letters and common numeric substitutions, reject invisible/homoglyph characters, block reserved staff names and inappropriate terms. A filter cannot recognize every possible offensive reference; administrators can disable accounts.

## Save-loss protection and recovery

The reported home-browser profile cannot be examined remotely, so recovery is not promised and the freeze's cause remains unconfirmed. Do not clear that browser's site data if attempting recovery. Existing profile downloads may still restore progress.

A rejected/corrupt local profile now preserves the primary and backup files, pauses progression-file writes and shows recovery options instead of silently saving a new default profile over them. The recovery screen can download the preserved raw files on the web or import a player backup. Writes using a schema validator also reject invalid new data before replacing the previous file. A cloud save's ten-revision history is separate from local backup files and from the database provider's disaster-recovery backups.

## Community records

Existing anonymous hero/realm totals and earlier fish/crop records remain. New authenticated contributions add public usernames; an old anonymous record is not relabelled as a different player's smaller new result. School codes and account IDs are never public.

- Top five accounts for all-time damage, matching the lifetime damage used by the five-star ranked cosmetic.
- Top five accounts for rolling seven-day damage, matching crown timing. This is a rolling window, not a Monday reset.
- Fastest completion of each ordinary realm, all time and this week, with username and time. Solo and co-op completions both count; co-op credits each participating account. Times begin recording in v188 rather than guessing missing historical durations.
- Top five longest life streaks: realm clears without a defeat, all time and this week. Any tracked solo/multiplayer defeat resets the current streak; the best remains. Training/tutorial practice does not count. These begin in v188.
- Named top-five solo and co-op Between extraction records. The shared co-op haul appears for each participating account, not a claim about which teammate individually picked up each shard.
- Fish weight/rarity records and garden records now display usernames where authenticated records establish the result. Species pictures remain.
- A relic-find card with its illustration and finder. There is no existing universal relic rarity grade, so the visible comparison is explicitly Conclave-forged status, then overcharge tier, then natural roll quality. Upgrading a relic does not improve that score. Finds are archived even if later salvaged; retained relics seed the archive on first connection.

Monday-based weekly records retain the existing Edmonton town/server time. Public records remain client-reported progress associated with authenticated accounts; authentication does not turn the game into a cheat-proof tournament authority.

The town board now blocks its lower face and draws before the foreground player, so standing in front no longer hides the character behind it.

## Hero adjustments

- Stormscribe: Thunderfall stuns enemies it hits for two seconds, including travelling-orb impacts. Storm Aura replaces the old primary cooldown passive: self and allied heroes within 160 units move 15% faster once the passive is unlocked. Separate Storm Auras do not stack. Normal team/line-of-sight rules apply.
- Crumb Cook: Kitchen Confidence replaces Well Fed. Self/allied heroes within 160 units gain four percentage points of critical chance, with critical hits dealing at least 150% damage. Existing mastery/crown crit bonuses remain; duplicate Cook auras do not stack. The primary's arrow-like triangle is replaced by a slotted metal spatula with a wooden handle and a swing.
- Tova: lore, passive, secondary and mastery title refer to marsh lanterns instead of using Waylight as a second unrelated concept.

## Validation and limits

Validation results and test sources are included under validation/v188, qa and network_tests. They cover account separation, hashed/encrypted storage, duplicate/obfuscated names, roles, private identification, revision conflicts, history restoration, sessions, actual in-game cloud migration/load, admin controls, local recovery preservation, allied/enemy aura boundaries and the two-second travelling Thunderfall stun. Existing v187 combat/ranking/community tests are retained.

Local tests do not establish hosted school-network capacity or recover the missing profile. Deploy the server before the client and verify the two-device flow before inviting the full class. Keep independent database backups and player ZIP exports.
