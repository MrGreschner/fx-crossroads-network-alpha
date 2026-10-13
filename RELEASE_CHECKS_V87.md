# v87 release checks

- Roster audit: 60 heroes, zero errors.
- Godot 4.5.1 headless editor import: no script parse/load errors.
- v87_menus: numbering/search, double Escape, solo choices, live host choices, town restrictions, opposed beam ticks/rotation/expiry and snapshot replication: zero failures.
- v87_profile_reset: confirmed clear removes mastery, favourites and backup/temporary files and reloads the main menu: zero failures.
- Regression scripts v86_release, v86_multiplayer, v84_coop, v85_coop, v66_profile_restore, v76_onboarding: zero failures.
- Room service npm test: 24 passed, zero failed, including WebSocket recovery, capacities and protocol isolation.
- Native rendered main, clear, pause, hero hall, paired appearance, level cards and Owl Eyes inspected.

Headless shutdowns retain existing ObjectDB/resource-cleanup warnings. Physical mobile and live Render/itch.io deployment remain outside these checks. This is source, not an exported browser or Windows build.
