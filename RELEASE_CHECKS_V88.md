# v88 release checks

- Roster audit: 65 heroes, zero errors; all five have four poses and different first/final mastery ability slots.
- Godot 4.5.1 headless editor import: no script parse/load errors.
- v88_party: friendly and hostile darts, timed group healing, weighted cap/quiet merging/HP preservation, split capacity, ranged companions, warning/stun, projectile interception, snapshots, authoritative guest attacks, rival KOs, defence deaths and leaderboard visibility/sorting: zero failures.
- v88_solo: solo dispatcher, self-healing areas, cleansing, merge proximity, summon expiry/owner death, protective ward, marching sacrifice, traffic control and all ten mastery alternatives: zero failures.
- Regressions v87_menus, v87_profile_reset, v86_release, v86_multiplayer, v85_coop, v84_coop, v81_arena and v83_gate: zero failures.
- Room service tests: 25 passed, zero failed, including protocol 22 isolation, recovery and capacity checks.
- Native hero-hall portraits and all new pose assets inspected. Eight-player leaderboard rendered at 1280×720: panel 660×420, content minimum 624×392; rows, controls and footer fit.

Headless shutdowns retain existing ObjectDB/resource-cleanup warnings. Automated tests and native rendering do not verify physical mobile touch or live Render/WebRTC sessions. Test those briefly before publication. No browser/Windows binary is included; export fresh builds from this source.
