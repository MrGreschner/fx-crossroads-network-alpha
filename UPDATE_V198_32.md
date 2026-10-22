# Crossroads: Realms Beyond — v198.32 • Voyage Manifest

Build `V198.32-voyage-manifest`. Complete release based on v198.31, preserving the shared 24-hour clock, dark nights, irregular islands, ocean swells, marina and earlier game updates.

## Compact, informative voyage HUD

Anchor/Sail, Chart and Land/Board/Return now share a compact bottom-left control strip. Hull condition and kept cargo sit directly above the buttons. The top conditions badge shows the same weekday, time and weather as town, with a weather icon. A small-screen landscape layout moves the conditions badge to the opposite side to avoid the steering area.

The fishing XP pool shows the reward pending a safe return, including release, trophy, discovery and record bonuses. The bar fills toward the next fishing level and identifies projected level gains. It uses the same XP formula as actual awards and does not award anything early. It updates after catches, releases and perk changes, with cached calculation between changes.

## Cargo and fishing mastery

- Boat cargo begins at **20 kept specimens**, for both lake and ocean.
- The existing Trailcraft packing chain increases boat cargo: Angler Satchel +5, Careful Packing +5, Travelling Case +10, Specimen Crate +10 and Expedition Porter +10, for **60 maximum**. Existing owners benefit immediately; no mastery reset or XP conversion is required. Descriptions identify both collection and boat benefits.
- The collection bag now also starts at 20, so a new fisher can land a full starter boat. Existing level and packing upgrades remain, with the existing 100-specimen collection ceiling.
- Released fish never occupy cargo. They remain in a separate voyage log for discovery and release-bonus XP, still conditional on returning alive. Releasing a kept cargo fish frees its slot immediately and cannot be undone.
- A voyage is now one committed attempt: sail back to safe harbour, or end it and lose unbanked rewards. Suspend/resume controls are removed, including the regular town/main-menu exit loophole. Closing or reloading cannot resume a live trip. Old unfinished voyage snapshots cannot reopen; the pier explains that their unbanked rewards were not kept. Landed collections and existing XP remain unchanged.
- Live voyage cargo and the release log remain in memory. Only a reward transaction already started at safe harbour is persisted, so an interrupted safe landing can finish without reopening an expedition.
- Cage recovery checks kept cargo space and leaves the complete cage available if it will not fit. Wrecks/abandonment lose both unbanked cargo and the pending release rewards.
- The release log is bounded to 1,000 catches per voyage; return to bank the log if that limit is reached. Existing cages continue to use active voyage timers.

## Easier selling at Ripple & Reel

The marina menu now links directly to selling landed catches. Sales use compact rows showing artwork, rarity, weight, catch date and price, with details available separately.

- Check individual fish, select all search matches, select ordinary unprotected matches, or clear the selection.
- Review the selected count and quoted Glimmer total before selling in one batch. Selection survives sorting and filtering; hidden selections are included in the explicit confirmation.
- Trophies, Very rare+ fish, favourites and aquarium specimens are identified as protected and called out during confirmation. Ordinary-only selection excludes them.
- **Newest caught** is the default. Name, weight, relative size, rarity, oldest and sale-value sorting are available. New catches have a validated capture timestamp; old catches use date and existing collection order, preserving compatibility.
- Batch trade validates all IDs, availability, duplicate selections, price changes and wallet space before removing fish. One saved transaction credits the wallet and removes sold catches from the bag, tank placements and favourite. Journal records and fishing XP remain. Stale or repeated requests cannot sell the same fish twice.
- Prices, mastery bonuses and crown/daily-hero Glimmer bonuses remain consistent with single sales. No new currency or business system is introduced.

## Validation and manual deployment

**10,003 automated checks passed against the packaged runtime:** 64 cargo/XP/sales/exit checks, 3,921 sea-clock/island/wave checks and 6,018 Citadel/fishing/voyage regressions. These cover full cargo, release at capacity, manifest releases, committed exits, XP preview/award agreement, wreck losses, rejection of old unfinished voyage resumption, day/time/weather labels, HUD placement, batch confirmation/cancellation, exact batch payout, protected placements, stale IDs, duplicates, price changes, full wallet, sorting menu-exit confirmation/cancellation, and responsive sales layout. Existing sea and Citadel/fishing/voyage regressions are also run. Final logs are in `validation/v198_32`.

The source/server/web files agree; ZIP integrity, baseline preservation and a clean local server import/health boot are checked. Native exits retain existing resource-cleanup warnings. Real browser/device and student playtesting remains.

No production deployment, database migration, account reset or key changes. Deploy server first to Render, then web to itch.io, preserving the existing database URL, secrets, environment variables and persistent storage.

The server retains v198.31's lean packaging and disabled npm lifecycle scripts. The earlier Windows Defender alert has not been independently cleared here; no antivirus scan is claimed. Keep flagged downloads quarantined and use Microsoft's review process if necessary: https://www.microsoft.com/en-us/wdsi/filesubmission .
