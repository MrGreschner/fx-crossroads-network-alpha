# V198.40 validation

All tests use isolated synthetic accounts, saves and local servers. Production was inspected read-only; no production deployment or MVP record repair was executed.

| Check | Result |
|---|---|
| Native Godot 4.5.1 custom-record eligibility | 21 assertions passed |
| PostgreSQL-compatible isolated database | 37 assertions passed |
| Dedicated authority / eight WebSocket clients | 15 assertions passed |
| Actual Godot multiplayer client | Warning, persistent Playtest label, custom identity and progression blocking verified |
| Browser administrator repair UI | Preview, no default selection, read-only totals, selected correction and restore availability passed |
| Existing realm/gameplay regression | 61 assertions passed |
| Existing structured-programming regression | 82 assertions passed |
| Production PCK logic | Same eligibility fixture run against the packaged resources (QA fixture injected into a separate copy) |
| Source/server/PCK parity | Every changed client resource matches; server-only service code matches source |
| ZIP integrity and contents | CRC, duplicate-path, executable/cache/secret exclusions checked |

Coverage includes an official hero setting a best, an actual approved public community hero setting an attributed best, modified approved-project rejection, rejection of local balanced drafts as competitive heroes, an unofficial flag surviving hero changes/player departure, a fresh official match counting again, forced balance enforced by the authority in public and private rooms, a real custom primary running on the server, acknowledgement gating before launch, malformed payload atomicity, missing/co-op/custom hero provenance, current server approval lookup, targeted repair backups, stale result suppression, restoration, and preservation of other records and progress.

The local custom personal-record migration also verifies that a custom result is archived while an official hero's identical numerical time remains intact. Other unattributed personal bests are intentionally preserved until reviewed.

Godot logic tests retain the previously observed shutdown-only ObjectDB/three-resource warnings. The older gameplay fixture also has an optional export path under `/tmp/crossroads38`; that directory must exist to avoid its unrelated export warning. The explicit V198.40 settings export uses its own valid path.

Fixtures are included under `qa/v198_40_*.gd` and `qa/v198_40_*.mjs` in the editable project. PostgreSQL tests use PGlite via `PGLITE_MODULE`. The networking fixture uses `GODOT_BIN`, `WS_MODULE` and `CUSTOM_FIXTURE`; generate the custom fixture using `qa/v198_40_project.gd`. QA scripts and private Node service code are excluded from the production browser pack.

Remaining checks: real-device solo/co-op/arena experience; deployment of server first, then browser client; and authenticated audit/correction of MVP's confirmed recent custom-hero results. Existing records remain client-reported rather than cryptographically proven offline results.
