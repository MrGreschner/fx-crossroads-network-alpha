# V198.38 validation

All checks used local files and synthetic accounts. No production deployment or production database mutation was performed.

| Check | Result |
|---|---|
| New gameplay integration | 61 checks, zero failures: timed openings and occupancy safety, actual Hart summon cycle, minion cap/death explosion, doorway collision, two hound spawns, across-wall casting, co-op snapshots, new art, merchant safety, daily portrait, terrain regeneration, recorded parties and solo/co-op Descent separation |
| Named records/database | 21 assertions passed with isolated PostgreSQL-compatible PGlite: two top-ten boards, ordering, captured party, rename handling, immutable faster crew, legacy metadata, rejected malformed data and disabled account-name handling |
| Existing community records | 21 checks passed: fish/trophy records, account identity, weekly rollover, authorization and public-response privacy |
| V198.37 gameplay regression | 308 checks, zero failures |
| Battlegrounds army regression | 271 checks, zero failures |
| Programming interpreter regression | 82 checks, zero failures |
| Shared Academy API | 74 explicit assertions plus request/status assertions passed |
| Creative source assessment API | 124 assertions passed |
| Actual client PCK | New gameplay 61 checks and programming 82 checks repeated successfully using the packaged resources |
| Browser startup | Actual Web build loads its WASM/PCK, completes the cinematic and reaches an active main-menu canvas without script/parse errors |
| Server startup | Clean Godot import and dependency install succeed; authority health reports V198.38, protocol 11 and 23 Academy modules |
| ZIPs and parity | ZIP CRCs pass; 55 changed client resources match editable source, server and PCK bytes; private server code/curriculum and QA are excluded from the client pack |
| Native visual checks | Rendered Foundry, timed gates, Hart/scarabs, secret doorway/hounds, relocated shop, Character Hall, Descent boards, co-op speed records and both Battlegrounds terrain types; compact records panel also checked |

The previous release’s complete teacher flow, public code/vector tools and related QA sources remain included. No changes were needed to their assessment catalogue in this update.

## Foundry measurements

With native Godot 4.5.1 under local software OpenGL, the old world-drawing function measured roughly 4.3 ms median, versus roughly 0.18 ms for the new batched geometry. The comparison uses the same camera and viewport. A 10,000-point collision comparison matched the previous map exactly; cached geometry reduced collision-check CPU cost in repeated local runs.

This measures script-side drawing submission and collision work, not overall game FPS, network latency or student-device performance. The meshes build on realm entry and are released on leaving. Turbines, water motion and combat remain animated.

## Limits

- Classroom/database tests use isolated synthetic accounts and a serialized PGlite adapter, not the live Render PostgreSQL database under classroom-scale concurrency.
- Community scores are client-reported. The new metadata preserves recorded heroes/partners; it cannot reconstruct information never saved in older records.
- Old combined Descent bests do not always establish whether the run was solo. Only provable values are backfilled into the separate modes.
- Student-device FPS, live two-device co-op synchronization and final enemy/timing balance still need playtesting.
- Existing test-exit ObjectDB/resource cleanup warnings remain. The new visual run has no remaining script errors; the detached progress-check error encountered during testing was guarded.
- Comparative QA can use `FX_QA_BASELINE_ROOT` pointing to an extracted V198.37 editable project. If the baseline is unavailable, the optional old/new Foundry comparison is skipped; gameplay checks still run.

Use UPDATE_V198_38.md for deployment order. Package parity, actual Web PCK execution, browser startup, authority startup and ZIP integrity passed locally. The server startup test intentionally used no database; live database-backed services must be checked after deployment with the existing configuration. External service fetches were unavailable during the local browser boot test.
