# V198.41 validation

Tests used isolated synthetic users, saves and local servers. The live service was inspected read-only; no production records, accounts or keys were changed.

| Area | Result |
|---|---|
| Godot eligibility, damage and main menu | 27 checks passed |
| Access and duplicate cleanup | 17 PostgreSQL/PGlite assertions passed |
| Existing record/repair regression | 37 PostgreSQL/PGlite assertions passed |
| Teacher browser | Actual same-origin form login, teacher role, handoff, cookie exchange and workspace loading passed |
| Repair browser | General selected repair and MVP preset passed; twelve matching copies removed, unrelated damage row preserved |
| Dedicated multiplayer | Eight socket clients plus actual Godot client; 15 assertions passed |
| Packaged game logic | Eligibility fixture run against an isolated copy of the production PCK |
| Release integrity | Source/server/PCK byte parity, ZIP CRCs, duplicate paths, version and private/cache/native-executable exclusions checked |

The damage tests include a custom hero attempting to add damage with the run marker deliberately removed; direct calls to lifetime, weekly cosmetic and rolling crown award paths; known old custom damage archived only once; official hero damage; approved public community hero damage; and server rejection of a forged declared lifetime total or custom IDs in the eligible damage ledger.

Cleanup tests cover one selected solo time expanding to four weekly/all-time/combined copies, an equal-valued official co-op result being preserved, an intervening cloud auto-save, verified absence after repair, and restoration of the backed-up rows. The browser preset exercises all three reported MVP realms and twelve matching copies. No automatic choice is made for other unknown-hero records.

A custom multiplayer rendering error was also found while checking actual client logs: the shared Studio renderer read a solo-only hero property on an arena client. The party runtime now supplies its own visual identity. The actual client regression rejects script errors rather than relying on its exit code alone.

Native logic tests retain previously observed shutdown-only ObjectDB/three-resource warnings. Networking fixtures allow cold Godot startup time; this does not change gameplay timing or production limits.

User-facing deployment and cleanup instructions are in UPDATE_V198_41.md. Real-device playtesting and the authenticated live MVP repair remain pending. Unattributable historical network damage totals were preserved for evidence-based review rather than reset.
