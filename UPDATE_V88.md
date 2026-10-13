# FX Crossroads v88 — Team play and live leaders

Complete editable source, including v87. All 65 heroes remain unlocked; existing hero IDs, roster numbers and portable profiles are preserved. No deployment has been performed.

## While waiting to return

Dead/downed multiplayer players see a compact live table with damage, all kills, opposing hero KOs and deaths. It highlights their row, names the damage/kill leaders, and offers damage or kill sorting. A respawn countdown is shown when applicable; co-op instead shows Awaiting revive. The window closes on revival or match results and fits up to eight fighters. Spectators are not added as fighters. These are current-match figures, separate from persistent PvP trophies. Ally guards' kills are not credited as a player's personal kill.

## New heroes

| No. | Hero | Role | Play style |
|---|---|---|---|
| 61 | Lumen Courier | Support / Ranged | One dart damages an enemy or heals an ally; secondary fires five darts in a fan. An aimed relay heals and protects nearby friends. |
| 62 | Harbor Bell | Support / Control | A penguin with a slowing close-range note, healing buoy and moving protective passage that intercepts hostile shots. |
| 63 | Mosaic Tender | Summoner / Control | An axolotl who places living tiles. Up to five pieces quietly merge into stronger companions; split and rally them, or deliberately combine them for battle. |
| 64 | Clockwork Apiarist | Summoner / Ranged | A beekeeper engineer who places ranged hive drones and commands them to regroup and release a coordinated volley. |
| 65 | Velvet Bailiff | Control / Ranged | A tortoise whose slowing threads, sideways traffic field and delayed stunning court control space rather than maximise damage. |

Every hero includes four matching pixel poses, hero-hall descriptions, role filters, a mastery title, two independent selectable mastery alternatives and the existing mastery/crit progression. The mastery catalogues and ability catalogue include the new options.

### Healing and summon limits

Lumen's primary deals 16 damage or heals 7; the fan's five darts each deal 10 or heal 4. Darts stop at their first eligible target and do not self-heal. A teammate can catch a dart intended for an enemy, so positioning matters. The relay heals 6 HP per second for three seconds. Host authority decides hits and healing, including guest casts.

Each mosaic piece starts with 32 HP and lasts 14 seconds. Pieces merge only after two quiet seconds with no hostile near their owner or any piece. Nearby pieces combine their actual remaining HP, gain damage and refresh lifetime; merging never grants a free heal. A five-piece creature still occupies five slots, so primary cannot create a sixth piece. Scattering preserves health and remaining lifetime. Drones are capped at three, or four with the passive, and expire after 16 seconds. Summons are removed when their owner dies.

Hostile-shot interception uses bounded catches. Control fields have visible areas and delayed attacks give a warning. New effects are capped and included in multiplayer snapshots; existing heroes retain their combat defaults.

## Publish this version

Deploy the included **room_service 22** to Render before publishing the v88 game exports. The existing URL, environment variables and start command are unchanged. Players must use matching game versions. Export fresh Web and Windows builds and upload those builds to itch.io; this ZIP is editable source, not the browser export. See RELEASE_CHECKS_V88.md for validation and device-check limits.
