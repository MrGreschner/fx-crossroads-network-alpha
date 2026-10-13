# v123 — Crossroads Studio, stage one

Adds the Hero Workshop from the main menu and Character Hall: guided concept/artwork/ability/passive/mastery authoring, 17 working ability behaviours, bounded tuning, portable project JSON, independent one-click playtests, local draft autosave and readable/data test reports.

Four uploaded PNG poses are embedded in the portable project. Validation rejects player profiles, unsupported script fields, invalid values, unsupported versions and oversized artwork. Test runtimes cap projectiles, fields and minions, and do not mutate the player's profile, gold, public roster or multiplayer state.

The workshop has its own stable versioned schema/API, with the future code-lab extension disabled until an appropriate restricted runtime is implemented. This stage does not include a pixel editor, arbitrary code execution, publication into live matches, or every hero-specific attack from the main roster.

Read `HERO_WORKSHOP_GUIDE.md` for the student workflow, supported behaviours, example assignment, portability and developer extension points.

## Deploy

1. Open this editable project in Godot 4.5.1 and allow imports to finish.
2. Export the Web preset into a new empty folder. ZIP its exported contents (index.html at ZIP root) and replace the playable HTML5 upload on itch.io.
3. If offering Windows downloads, run the included Windows build workflow and replace that ZIP too. Students should use matching versions.
4. Render needs NO changes or redeployment: this update is client-only; room/server/package files are unchanged.
5. Before class, smoke-test Open project, Playtest, Finish & report and downloads in the actual school browser. Also test once in the Windows build if distributing it.

This ZIP contains the editable project, not a pre-exported Web or Windows game.
