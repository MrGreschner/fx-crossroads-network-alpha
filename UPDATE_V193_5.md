# Crossroads v193.5 — fishing records and account heading

Upload Crossroads_v193_5_Web.zip to the existing itch.io game. Keep the HTML game entry enabled. The editable ZIP is the Godot project for local editing.

## Server update (required for immediate refresh and rarity tie fixes)

Crossroads_v193_5_Server_Update.zip is a small update for your existing v193.2-profile-core server repository, not a complete replacement repository.

Extract it. Upload the included `network_service` and `network` folders into the existing GitHub repository root, preserving these paths and replacing the four matching files:

- network_service/community.mjs
- network_service/named-records.mjs
- network_service/release.mjs
- network/release.gd

Commit, then deploy the existing Render service. Do not delete the other repository files. Do not change CLOUD_SAVE_KEY, DATABASE_URL or other private Render settings. The same account encryption key and existing database are retained. Deployment restarts active matches. The two previously removed browser account-control files remain absent; password-reset administration is not reintroduced.

## What changes

- Fishing records and species trophy holders show the species rarity in colour, independently of trophy size.
- Weight dials compare the catch with its own species. Teal tick: average ordinary weight. Gold tick: trophy threshold at 250% of average. Full dial: species maximum possible weight. Exact kg and percentage remain readable.
- Signed-in cloud save page reuses your graphical player card, including the selected portrait, records and favourite fish. It scales to the available width; Save now stays above it. The card appears after adopting/loading the cloud profile, so a guest profile is not presented as your account’s progress.
- Town heading: CROSSROADS: REALMS BEYOND | authenticated username. Signed-out sessions show Guest. Narrow screens use a compact two-line title.
- Resync my records uploads the active profile first, then fetches the board; status explains success or failure. Merely signing in without choosing a cloud profile does not claim the guest profile's records.
- Loading/adopting a cloud profile, successful cloud saves, catching fish, and returning to town schedule records updates. Periodic uploads continue as a fallback. Active cloud records do not depend on optional diagnostic-report consent.
- Existing trophy catches in the species journal are included in named all-time submissions, including released fish. Ordinary catches do not qualify for the species trophy list.
- Equal named and anonymous catches can display the authenticated holder. Heavier anonymous records are not reassigned to an account by guesswork.
- Successful server uploads invalidate the community board cache; same-species rarity records now update when a heavier catch is submitted.

Cloud saving and public community records are separate operations. A sync only publishes records from the active profile; it does not load or overwrite cloud progress. Old catches without saved weekly tracking cannot be assigned to a guessed week. Public records remain client-reported, not authoritative anti-cheat scores.

## Quick check after deployment

1. Sign in, then load your cloud profile or adopt this device's existing progress.
2. Confirm your username appears in the town heading.
3. Open Community Records, select Fishing records, and press Resync my records.
4. Wait for the upload and board refresh. Trophy journal catches can populate species holders. Your name appears where your catch actually holds the record.
5. Check on another device after its board refresh. Keep a downloaded backup until cloud save/load has been verified.

## Validation

- 21 local PostgreSQL-compatible account/community integration checks.
- 22 Godot client checks: rarity, dial values, trophy journal payload, authenticated identity, title and sign-out state.
- 7 Godot HTTP checks plus server-side request-order assertions.
- 35 existing profile-core checks and 14 public-account/Descent-marker checks.
- Browser render and startup checks. No production accounts or records were changed by the tests; no live deployment performed.
