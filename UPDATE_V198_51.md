# Crossroads: Realms Beyond — V198.51

Build V198.51-business-gameplay. Cumulative over V198.50. Godot 4.5.1; multiplayer protocol unchanged.

## Manage Class Pro

- Assignments sidebar tab renamed Modules, preserving the older `?view=Assignments` shortcut.
- Venture access & progress is a dedicated sidebar workspace, with Class spreadsheet, Venture access and Restart requests sections. Its old primary button is removed from Learning Academy.
- Student spreadsheet: owned ventures, current cash and reserve, completed and profitable venture-days, employees, operating profit, approved/pending restart counts and last save.
- Separate per-venture rows show current workday, full/profitable days, streak, cash, debt, employees, spoilage cost and trading status. Class comparison chart, sorting, search, class/module filters and CSV export are included.
- Permission checkboxes apply to selected students or the visible class. Mixed permissions are shown as mixed; only changed boxes are applied. Bulk changes preserve unrelated permissions, module slots and placement. The server checks ownership and revisions and rolls back the whole batch on a stale policy.
- Existing per-student business inspection and sales charts remain available. Pending restart reviews are also accessible from the new workspace.

## Business learning through gameplay

All 13 Business modules have a baseline → test → review investigation linked to operating an actual classroom venture:

ENT1010, ENT1020, MAM1010, ENT2010, ENT2020, ENT2030, ENT3010, MAM3050, ENT3020, MAM1020, ENT2040, MAM3010, MAM3130.

- Business Studio tab becomes Run & review. The disconnected planning boards are removed from the active Business workflow. Creative subjects retain their public Studio tools and existing workflows.
- The workspace shows actual operating-profit charts, saved decisions, workday progress and frozen account-linked checkpoints. Students enter the same living district to change products, ingredients, equipment, staffing, prices, advertising, layout and routes; the existing simulation produces customers, queues, sales, waste and financial effects.
- Guidance for every business outcome now identifies the actual district controls, relevant workday evidence, decisions and required explanation. Research, presentations, regulatory comparisons and observed customer-service demonstrations remain where gameplay alone cannot demonstrate the main outcome.
- Introductory projects target 12 new full workdays, Intermediate 18 and Advanced 30, across three checkpoints. These are active simulated openings, not calendar days. One full opening is 180 active seconds. Investigation, research, revision and teacher discussion add to that operating time; these targets do not enforce a real-world number of school days.
- A baseline fixes one focal venture. Other ventures cannot multiply project-day progress. Previous workdays, repeat saves and partial openings do not count as new project workdays. Later checkpoints require an actual saved venture decision followed by a completed opening.
- Partial submissions still receive feedback. New-edition completion requires the frozen gameplay checkpoints or a documented teacher accommodation/equivalent-evidence decision, plus the existing passing mark and Meets/Extends judgement on every main outcome. Profit and play time never grade a student automatically.

## Existing work and evidence limits

Completed grades and frozen submissions are not rewritten. New assignments use edition academy-7-gameplay. Existing assignments receive the updated workspace/guidance and can begin a new investigation; their original completion contract is retained rather than retroactively imposing new gates on already assigned work.

Checkpoints are captured by the server from the student's account-linked saved district and included in the frozen submission digest. The simulation still runs on the student device. These are client-reported learning records, not cryptographic proof of honest gameplay; teacher observation and judgement remain necessary. A borrowed screenshot alone cannot supply the account-linked checkpoints.

The spreadsheet reports latest synced classroom progress, not the public fantasy market. It falls back to older module district saves where a shared district has not yet been created. Restart counts are approved requests retained on the server; they are not guesses from the current day counter. Venture-day totals add across current businesses; use the per-venture rows to judge how long one business has operated.

## Data and performance

Two additive tables store deduplicated full-day evidence and immutable checkpoints. No data deletion or record reset occurs. Daily reports are inserted in one batch per changed district save; refreshes do not manufacture progress. The class overview projects only the needed business summaries instead of transferring full inventory and staffing-profile save payloads. Charts reuse existing fonts and bounded histories; no new town agents or per-frame server simulation is added.

## Validation

- 30 full workdays generated with the actual Godot business simulation using a funded test fixture.
- 79 isolated PostgreSQL-compatible integration checks: curriculum projects, gates, account isolation, deduplication, partial openings, focal-venture counting, decision/operation requirement, frozen evidence, partial feedback, completion accommodation, atomic stale-policy rollback and legacy district fallback.
- 70 existing Academy/scope regression checks passed.
- Browser interaction checks passed for the renamed sidebar, spreadsheet, saved bulk permissions and class-only changes that preserve other students' access; no page script errors.
- All 13 Business gameplay workspaces rendered in the native client and visually inspected with the spreadsheet/permission screens.
- Packaged-client startup and runtime resource parity, archive CRCs/roots, version markers and checksums verified.
- Existing Godot fixture teardown emits ObjectDB/resource-in-use cleanup warnings. Real classroom/device testing remains; no live deployment or production data changes were performed.

## Deploy

Back up the service/database, deploy Server Update to Render first (automatic additive schema setup), then upload the Web ZIP to itch.io. Preserve all database connections, keys, environment variables, account/save data and existing storage. Refresh the teacher browser and game after deployment. Use the normal migration/deployment backup process; no manual deletion is required.
