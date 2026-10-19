# Crossroads: Realms Beyond — v182

## Upload order
1. Upload the contents of Crossroads_v182_Server.zip into the existing GitHub server repository, replacing matching files and adding the new files. Deploy the latest commit in the existing Render service.
2. After deployment succeeds, upload Crossroads_v182_Web.zip to the existing itch.io game as the playable HTML build.
3. Use Crossroads_v182_Editable.zip for Godot editing/debugging.

Keep the existing database, service settings, environment variables and report credentials. No database reset or manual migration is required. New fields use the existing report tables. Client and server both identify as V182-preview; network protocol remains 11. Existing player saves remain compatible.

## Private report page
Open your existing Render service URL followed by /reports. Sign in with the existing report credentials. /activity opens the same dashboard. The in-game Game Dev activity page also links to the full dashboard.

Choose a mode across the top: Arena / VS, Normal realms, The Between, Overcharged realms, Ram’s Descent, Gate Defence, Battlegrounds, Quest Area / Wayfarer, Town, Fishing, Deepwell Mine, Market, Studio / creation, or Menus. Narrow by period, connection type, device platform, controls, realm, hero or build.

- **Play overview** compares recorded active time, anonymous profiles/devices, outcomes and sampled performance by mode. Select an activity to inspect sessions.
- **Multiplayer matches** compares devices in the same match, with FPS and round-trip graphs, rendering and server workload, movement corrections, shot timing, disconnect/sleep context and AI/player counts.
- **Activity sessions** shows local solo and town activities as well as multiplayer. Session details include frame-time buckets, firing/idle comparisons, mine progress, fishing catches/XP/trophies, and available market metrics.
- **Exports** download filtered activity data or a selected match/session as JSON for further investigation. Bounded lists/exports say when they reach a limit. Tighten filters or export separate periods in that case.

Missing measurements are shown as unavailable rather than zero. Older builds remain visible; their new fields cannot be recovered retroactively. Window summaries are labelled separately from one-second match samples. Warnings suggest what to investigate; they do not establish a cause. Intentional FPS caps and hidden/sleeping browser samples are considered when comparing devices.

## What is collected
Anonymous session/profile/device identifiers; mode, realm, hero, client/server version, outcome and duration; device renderer and controls; bounded frame/render/workload summaries; existing detailed multiplayer network/action timing. Fishing catch events record species ID, weight, level, XP, trophy and keep/release status. No student names, assignments, chat, saved profiles or passwords are included in these reports.

Collection remains asynchronous and bounded: local activity windows flush around once per minute or on context changes, and detailed multiplayer batches around every 15 seconds. Game Dev/practice and player opt-outs remain excluded. Retention remains 30 days. Anonymous identifiers are not student headcounts and these reports do not establish learning outcomes. Optional auto-refresh is off by default.

## First hosted check
After both uploads, complete a short normal realm, fish once, and play a multiplayer match. Allow a minute for activity uploads. Open /reports, filter to V182-preview, and confirm those sessions appear. Compare devices from the multiplayer match. For tomorrow’s larger test, note the approximate time, mode, hero and device whenever a student reports a problem. Export that match/session for review. These hosted checks still need to be performed after deployment; the local checks do not prove school-network behavior.

## Validation
Validated the report/API queries using PostgreSQL-compatible PGlite, authentication and data allowlists, all mode filters and exports, historical report classification, device comparisons, dashboard browser behavior at desktop/mobile sizes, native client telemetry, and multiplayer team/AI compatibility. JSON results are included under validation/v182 in the editable project. Browser screenshots and test dependencies are not shipped.
