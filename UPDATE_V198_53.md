# Crossroads: Realms Beyond — V198.53

Build V198.53-teacher-controls. Cumulative over V198.52, including the community-records loading hotfix and the Business/Manage Class Pro update. Godot 4.5.1; no broadcast protocol or new database schema change in this update.

## Broadcast controls

- Replaced the unbacked bottom-left controls with an opaque, bordered presenter panel centred beneath the top HUD. It shows the live broadcast code, Viewer seats and a clearly labelled, high-contrast End broadcast button.
- Controls account for the viewport/window scale so smaller windows do not shrink the labels into unreadable buttons.
- The viewer-seat window also shows End broadcast for the teacher. Return to broadcast simply dismisses that window, rather than sending another start command.
- End broadcast uses the existing leave/close protocol. The room service closes all viewers and the client restores each viewer's own game; the teacher's existing pause state is preserved.
- Private assessment screens remain excluded from broadcast capture. No new desktop, microphone, webcam or input sharing is introduced.

## Manage Class Pro

- Students becomes Students & classes, with an All classes directory that remains available even when the filtered student list is empty.
- Class cards provide roster view, rename/archive/restore, linked-student roster management, module/submission shortcuts and roster CSV export. Archive and membership changes retain submitted work and grades.
- Existing student class membership/progress controls remain. Student progress now includes current Academy attempts/completions rather than relying solely on the older portfolio summary.
- Student module progress moves from the bottom of Learning Academy to Overview. Class, module and student filters are available there. Learning Academy focuses on module lessons, rubric inspection and assignment setup.
- Existing Students/Assignments URL shortcuts remain compatible; the native teacher menu now links to the current Students & classes and Modules views.

## Old examples and local menu

The old Example screen used the earlier local portfolio, prompt-completion and provisional-scoring model. It did not represent the current frozen submissions, main-outcome assessment or gameplay checkpoints, so it has been removed from the teacher dashboard.

The local dashboard remains only for older local class records/backups and is explicitly labelled LOCAL CLASS BACKUPS — LEGACY. Its provisional automatic score summaries are removed. Current modules, cloud submissions and marking are directed to Manage Class Pro. Existing local records are not deleted. Current worked examples within module lessons and rubric inspection remain available; no fictional student records are added to the live Pro workspace.

## Validation

- 23 native checks passed: presenter-panel bounds in three viewport shapes, readable End button, opaque backing, viewer-seat return, private-review capture hold, host pause preservation, guest restoration, removal of the obsolete Example button and updated native teacher links.
- Native broadcast controls, class directory and Overview progress table rendered and visually reviewed.
- Browser tests passed through the real isolated classroom API: progress-table move, class listing, rename, roster add/remove, archive/restore with membership retained, roster CSV download, module links and rejection of another teacher's class edit. No browser page-script errors.
- Four existing room-service tests passed. A dedicated explicit End/leave test additionally closed all 31 viewers and confirmed repeated leave is harmless.
- Production client startup, changed-resource parity across editable/server/web, archive CRCs/roots, version markers and SHA-256 checksums checked.
- Native fixtures emit existing ObjectDB/resource cleanup warnings at shutdown. Real teacher/student device testing remains. No live deployment or production data changes were performed.

## Deploy

Deploy the V198.53 Server Update to Render first, then upload the Web ZIP to itch.io and refresh both the game and teacher browser tab. Keep existing accounts, database, saves, keys, environment variables and persistent storage. The separate broadcast room service uses its existing protocol; this update does not require changing that service's code.

Use V198.53 directly; it includes the fixes in V198.52, so a separate intermediate upload is unnecessary.
