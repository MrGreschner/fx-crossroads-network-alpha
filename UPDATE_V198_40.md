# Crossroads V198.40 — Fair play and custom heroes

This cumulative release builds on V198.39.1, including the town performance work and Manage Class Pro launcher repair.

## What changes

- Official heroes and exact approved public Community Heroes snapshots can earn records. A local draft, class Showcase approval, community-looking name, or Forced Balance checkbox does not grant competitive approval.
- Old personal bests explicitly attributed to local custom hero IDs are preserved in a separate unranked profile archive; equal-time official hero results remain intact. Unattributed legacy bests require targeted review.
- A local custom hero starts an **unofficial Playtest** run. Personal realm bests, community realm times, Descent records, Between records, damage rankings, streaks and tested competitive progress paths are blocked. The run shows a clear warning and an on-screen Playtest label. The Studio and custom gameplay remain available.
- One unapproved custom hero makes the **entire multiplayer match** unofficial, including teammates and opponents. The flag stays set if that player leaves. A new all-official match can count again.
- Custom multiplayer heroes must pass Forced Balance in both public and private rooms. The dedicated server validates their full projects, distributes artwork/abilities in bounded chunks, and waits for every player to verify the build before starting. Custom abilities run on the authority.
- The records server checks the official/public-approved hero catalogue and requires matching hero provenance for new realm, Descent and Between bests. Co-op results require an eligible party. Older clients cannot upload new combat records/rankings through the vulnerable legacy path. Existing historical rows are preserved.
- Uploads and repairs serialize by account, so an in-flight stale record upload cannot race a repair. Selected excluded values cannot return through record uploads or cloud saves.

## Deploy — server first, then itch.io

1. Deploy **Crossroads_v198_40_Server_Update.zip** to the existing Render service. Preserve the existing database and all environment keys, including DATABASE_URL, CLOUD_SAVE_KEY, REPORT_SIGNING_SECRET and REPORT_ADMIN_PASSWORD. Do not create a replacement database or reset accounts.
2. Confirm the service health reports **V198.40-fair-play** and accounts/community records are ready.
3. Upload **Crossroads_v198_40_Web.zip** to the existing itch.io game. Players should refresh to use the matching client. The older client remains playable but its combat record uploads are no longer accepted by the updated server.
4. **Crossroads_v198_40_Editable.zip** contains the full editable Godot project and the new regression fixtures.

No production deployment or database mutation was performed while preparing these files.

## MVP — live correction still pending administrator access

The public board was inspected read-only. It showed MVP with hero attribution missing on these displayed bests:

| Route | Record | Displayed value |
|---|---|---:|
| Solo | The Whispering Grove (`grove`) | 37.6020933333326 seconds |
| Solo | The Ember Quarry (`quarry`) | 51.5714148888878 seconds |
| Solo | Honeyglass Gardens (`honeyglass`) | 95.609895999999 seconds |
| Solo | Ram’s Descent | Floor 33 |
| Co-op | Ram’s Descent | Floor 17 |

All-time/weekly copies of the three times were present, together with combined-time copies. These are **review candidates**, not proof that every listed result used a custom hero. Public rows do not identify the hero or date of each attempt. No MVP result has been deleted.

After deploying the server, open **Manage users → Repair records**, or:
https://fx-crossroads-network-alpha.onrender.com/records/admin

Use the existing private administrator login. Preview exact username **MVP**. Select only the confirmed custom-hero results, including their combined/solo/co-op and weekly/all-time copies. Supply the evidence/reason, then use **Back up & remove selected results**.

The repair is transactional and account-specific. It stores a recoverable encrypted cloud-save snapshot plus the selected board rows before changing anything. It removes matching personal named bests, matching custom-hero local realm times, and the selected network rows; unrelated official hero times, other players, creations, inventory, passwords, school roles and account IDs remain intact. Exact excluded values are blocked from stale uploads. The player must **load the repaired cloud save** to refresh personal records on their device.

The **Restore this repair** button restores a backup only if no newer cloud progress or replacement record would be overwritten. Otherwise it refuses and requires a reviewed merge. Older legitimate bests that were already overwritten cannot be reconstructed from a public board; they may need to be earned again unless an earlier save or report provides evidence.

Damage/streak totals are read-only in this repair page: the surviving record rows do not safely distinguish legitimate totals from custom-run contributions. Anonymous cosmetic rankings and earlier alternate profile copies may also need a separate evidence-based review. Do not reset those blindly. Authenticated history/report access is needed to determine which recent totals, if any, should be corrected.

## Verification

- 21 native Godot eligibility checks: official vs local custom, local balanced drafts, true public approval, modified approval snapshots, mixed parties, sticky unofficial state and record/progression sinks.
- 37 isolated PostgreSQL/PGlite assertions: approved catalogue checks, legacy/missing/custom provenance rejection, official co-op, atomic malformed uploads, narrowly scoped repair, backup/restore, stale upload suppression and preservation of other records.
- 15 live-socket checks: eight clients, validated custom transfer, acknowledgement gating, authority snapshots/combat, persistence after a custom player leaves, fresh official match, and a real Godot client's warning/badge/blocking behavior.
- Browser admin workflow: preview, no automatic selections, read-only unattributable totals, selected correction and restore availability.
- Existing gameplay regression: 61 checks. Structured-programming regression: 82 checks.
- Release pack/source parity and ZIP integrity checks are recorded in VALIDATION_V198_40.md.

The existing record system is still client-reported. This closes the supported client's custom-hero exploit and enforces reported hero approval on the service; it is not a complete anti-cheat system against arbitrarily modified clients. Real-device co-op/arena playtesting and production deployment/repair verification remain necessary.
