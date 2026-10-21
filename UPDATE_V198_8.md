# Crossroads v198.8 — Community Records Hall

Build V198.8-community-hall · protocol 11 · Godot 4.5.1
Based on v198.7.1. Includes the report-timeout/download hotfix and all accepted v198.7 hero, combat guide, fishing and arena work.

## Install

1. Update the existing Render multiplayer service using Crossroads_v198_8_Server_Update.zip and your usual source/deploy process. This is the complete server project.
2. Preserve the existing database and all environment variables, accounts, cloud saves, signing secrets and encryption keys. No reset or manual database migration is required.
3. After Render is ready, upload the contents of Crossroads_v198_8_Web.zip to the existing itch.io HTML5 game and refresh the game.
4. Keep Crossroads_v198_8_Editable.zip as the complete editable Godot source.

## Records navigation

The main player menu and record categories are separated by a divider and an outlined COMMUNITY RECORDS / CHOOSE A BOARD panel. The record categories and Resync button live outside the results ScrollContainer: Hero damage, Fishing records, Realm records, Between runs, Garden fair, Life streaks and Relic finds stay available while scrolling. Selecting a different board returns its results to the top. Records & style is highlighted in the main menu while viewing community records.

The records window uses more of the available screen on larger displays. Narrower screens wrap category buttons and stack the rank columns.

## Top-ten damage boards

- Top 10 heroes: ranked by cumulative damage across connected portable profiles, rather than a new pick-count metric. Ranks 1–5 appear on the left, 6–10 on the right, with hero portraits.
- ALL-TIME DAMAGE: replaces FIVE STARS, displays ten named cloud accounts, and places the Eternal Constellation artwork beside the first five names.
- WEEKLY DAMAGE / VANGUARD COMETS: replaces the record hall's CROWN CHASE / ROLLING SEVEN DAYS panel. It displays ten accounts and the Vanguard Comets artwork beside the first five names. Vanguard Comets now qualifies the top five weekly damage profiles, matching the requested top-five distinction; the fishing award still qualifies ten.
- Weekly damage follows Monday 00:00 in America/Edmonton, matching the weekly cosmetic. Existing rolling-seven-day damage crowns retain their own rolling calculation. The old rolling API field remains available.

Empty slots are labelled rather than filled with invented scores. Existing totals remain high-water records; resyncing does not add the same profile damage again.

## Hero portraits on run records

Realm speed records show each winner's recorded hero, separately for all time and this week. The realm entry's solo/co-op community best cards also show the hero. Between extraction leaders show the hero used by that participant.

The hero ID is captured when a matching best result is achieved, stored with that exact value, synced in existing JSON metadata and returned with the record. Co-op uses the participant's actual assigned hero, including a hero that differs from the menu selection. Slower/stale uploads and ties cannot rewrite a known winning hero. A matching value may fill previously missing metadata.

Older records did not store the hero, so they display a neutral portrait and Hero not recorded. Current selection is never used to guess a historical winner. New or matching best results supply the missing attribution. No old scores are removed.

A co-op check also exposed an older personal-best notification referencing the solo scene's realm table. Its realm-name lookup now works in the co-op scene, allowing the rest of the record/streak update to finish.

## Silver Revenant

The previous code labelled the undefeated reward Wisp Skull and the floor-50 reward Silver Revenant. Their names and artwork are aligned with the requested meaning:

- Silver Revenant is the undefeated-this-week reward. Auto now displays it in solo town, and the same effect is carried into multiplayer appearance. The first death removes eligibility until the Monday reset. Explicit None still hides effects; choosing another style respects that choice.
- Wisp Skull is the permanent floor-50 reward.

Existing internal IDs and unlock conditions are retained: weekly_1 remains the undefeated condition, weekly_2 remains the floor-50 condition. Existing cosmetic selections are not erased. Weekly visual dates use the ranking calendar for Silver Revenant.

## Validation

- New records server suite: 37 checks passed, with twelve fixture accounts/profiles, top-ten order/cutoff, weekly versus rolling periods, top-five signed awards, metadata updates and preservation, disabled-account filtering and public-data privacy.
- New client suite: 55 checks passed in the native source build and again against the packaged web PCK. Includes real mouse clicks on pinned tabs while scrolled, two-column ranks, correct award counts/artwork, responsive narrow layout, portable-profile validation, solo/co-op actual-hero attribution and undefeated/opt-out/reset behavior.
- Existing community API suite: 23 checks passed.
- Existing named-record/trophy API suite: 21 checks passed.
- Existing report recovery suite: 32 checks passed.
- Existing historical report-data compatibility suite: 74 checks passed.
- Packed fishing regression: 246 checks passed.
- Web PCK checksums, ZIP CRCs and server runtime file completeness checked. The clean server archive imports and starts on protocol 11.

Preview images use illustrative records, not live database results. Production deployment and real-device playtesting remain manual.

Historical test note: the older v187 broad test still asserts a 24-soldier owner cap; the existing game uses 32. That unrelated assertion is stale; this update does not change battleground unit caps.
