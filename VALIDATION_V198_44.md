# V198.44 validation

## Automated checks

- **394 native operations assertions:** recipe/equipment/supply catalogue, 239 native illustrations, production, costs, procurement, staffing, maintenance, insolvency/recovery, rentals and save migration.
- **77 new-feature assertions:** 15 active plots/one blank, public acquisition and trading caps, no repeat startup grant, divestment/replacement, classroom independence, legacy sites, timed services, capacity, completion revenue and early-close losses.
- **39 API/database assertions:** native state acceptance, active salon/daycare/golf saves, invalid service timers, new/legacy permission IDs, role isolation, stale revisions, shared progress, frozen evidence and restart.
- **74 business academy regression assertions** and **70 academy outcome/history assertions**, using isolated PostgreSQL-compatible PGlite fixtures.
- **54 native module-scope checks:** existing assessment filtering and academy flow.
- **39 native town/combat assertions:** relocated Exchange collision, cleared former location, 30 sampled walking points, Lyra charge movement and interaction with slows, unchanged release damage.
- Five complete native first-day simulations: salon, daycare, golf, dessert and cafe generated valid reports.
- Browser checks: administrator dashboard, mobile overflow, teacher module filtering, fifteen venture gates, saved policy changes and frozen business/resume/day-metric review. No page-script errors.
- Native visual review: new businesses, service panels, district layout and Deepwell day/night placement. Screenshot fixtures use the software renderer; teardown reported resource cleanup warnings.

## Performance sample

Container CPU, headless simulation: 15 premises, 105 workers including owners, peak 64 customers, 1,000 ticks. Mean **1.970 ms**, p95 **2.634 ms**, maximum **5.098 ms**. Static furnishing is cached; closed off-screen businesses do not spawn idle workers. This is not a measurement of student-computer frame rate.

## Release checks

Release packaging checks cover archive CRCs, source/server/web resource parity, engine/build metadata, PCK privacy exclusions, and settings. Separate packaged-runtime native checks are recorded in the release parity output. Database fixtures are synthetic; no production data was accessed or modified.

## Remaining acceptance

Real-device playtesting is required, especially low-spec classroom graphics, longer multi-day service balance, new-business demand/pricing, teacher workflows with real classes, and Deepwell navigation by players. No live Render or itch.io deployment was performed.
