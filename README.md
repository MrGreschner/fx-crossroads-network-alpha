# T4.13 server connection repair

The original server delta ZIP omitted dependencies needed by the older GitHub server repository. This package supplies them and a startup validation check. It was tested against a fresh archive of the actual GitHub repository.

1. Extract this ZIP.
2. Open your GitHub repository MAIN PAGE, where network, scripts and project.godot are visible.
3. Choose Add file -> Upload files.
4. Drag the network and scripts FOLDERS from this ZIP into that page together. Keep these folder paths; do not upload the outer ZIP or loose files at the repository root.
5. Commit to the branch linked to Render.
6. In the existing Render game Web Service choose Manual Deploy -> Deploy latest commit.
7. Wait for Live, refresh the itch.io page, then press Host test room again.

Keep the existing T4.13 itch.io Web build, database, environment variables and passwords. They do not need replacing.

Expected: Host test room shows a six-character room code. Another player can join and the host can start the match.

Contents: three missing network scripts (dash_view, scenery_view, snapshot_inbox), updated movement helper, matching Arcade base script, and server startup guard. The supplied UID files keep script identities consistent.

Validation: clean Godot import of the actual repository; eight-player host/join and constrained movement; projectile travel; reconnect; Gladiator enemies and damage; actual Godot client. No script errors after repair.
