# v114 — Release polish and classroom playtesting

## Progress protection
First/final mastery eligibility sets a quiet backup reminder. Profile displays a compact backup/dismiss row and shared-device guidance. Main Menu labels the profile download button when a backup is due. There are no gameplay pop-ups or new goal notifications. A milestone is recognised once; a new final unlock can request another backup. Successful native file writes or requested browser downloads clear the reminder; browser text tells players to verify Downloads before clearing. Exported profiles carry the backup marker. Game Dev mode cannot set or clear progression backup milestones.

Existing last-good profile backups remain. Notebook drafts are separate; New/Clear player deletes the local notebook draft too. Downloaded files are not removed. Profiles remain local portable files, not authenticated online accounts.

## Combat feedback
- A small, short-lived contact spark confirms actual damage, across solo, tutorial, training and multiplayer damage routes. Zero-damage calls do not create sparks.
- Green plus marks confirm actual healing through shared hero healing and training ally helpers. Overhealing does not create a false confirmation.
- Contact cosmetics are limited to 24, merge nearby hits, expire after 0.18s and cull offscreen. They carry no gameplay authority or additional snapshots; existing multiplayer damage events are reused, with lightweight heal-contact cosmetic events.
- Enemy Cat invisibility is respected by contact feedback. No contacts or reach guides in town.
- Original heroes' instant primary strike visuals are bright for the initial 0.08s, then visibly faint afterimages until they expire, clarifying impact versus recovery.
- Options offers **optional melee reach guides**, default OFF. Faint blue directional arcs use the effective primary reach and arc for verified standard melee/identity-strike styles, including mastery alternatives. They are not an AoE attack, do not guarantee a hit through terrain, and are hidden in menus/for spectators. Special custom attacks retain their own authored indicators; this is not a replacement of every custom animation.

## Reporting and student tools
Options has an easy **Copy bug-report details** action, with version, browser/platform, GPU where reported, draw calls, engine memory, FPS/cap, mode, hero, viewport, role and testing status plus reproduction/expected/observed prompts. Copy requests do not submit anything. If clipboard access is blocked, the notebook offers a text download.

The **Student playtest notebook** has Testing, Issue 1–3, Reflection and Play & learn tabs. It keeps a small local draft, supports copy/download and confirmed clearing, and is separate from profile progress. Game Dev reports can be exported even though profiles/progression cannot. Editing saves after a short debounce instead of every keystroke. Reports label device/context at export, and students record actual test context in their notes. No automated submission or personal-name field is required. Live online games continue behind the notebook, as behind other menus.

The Play & learn tab and existing Adventure board provide a quiet overview of all game styles; no new gameplay goal pop-up was added. Elder Ram explains the student notebook.

## Classroom pack
student/ contains:
- PLAYTEST_ASSIGNMENT.md: three areas tested, three evidence-based improvements, verification and prioritisation; suggested 30-mark rubric.
- REFLECTION_ASSIGNMENT.md: evidence, trade-offs, player needs, collaboration and next experiments; suggested 20-mark rubric.
- REPORT_TEMPLATE.md: editable testing table, three issues and reflection prompts.
- TEACHER_GUIDE.md: lesson sequence, coverage groups, testing profiles, adaptations and re-testing later releases.
- CLASSROOM_PLAYTEST_PACK.pdf: printable compiled pack.

Grade/course-neutral so the teacher can adapt it. Success is assessed through evidence and reasoning, not scores or gaming skill. Student reports do not automatically prove testing occurred.

## Checks and limits
Godot 4.5.1 targeted checks cover first/final backup reminders, repeated-milestone suppression, Game Dev exclusion, bug-report context, notebook report fields/clear behaviour, capped/expiring/zero-damage contacts, effective reach values, town cleanup, invisible enemies, local/remote damage events, healing and multiplayer notebook access. v112/v113 regressions passed. Rendered and inspected Options, notebook, issue form, backup profile/main menu, and reach layouts. The 8-page PDF was rendered/inspected and all pages contain text. ZIP CRC and full extraction verified, with all v113 source payloads retained.

Physical phones, school browsers, live multi-computer play and compiled Web/Windows exports were not tested here. This does not establish that the previous WebGL crash is eliminated. Keep student real-device testing in the rollout.

## Deploy
1. Extract this source ZIP into a fresh folder and open FX_Crossroads/project.godot.
2. Re-export Web, ZIP exported files with index.html at the root, then replace the itch.io browser build.
3. Rebuild/upload exports/FX_Crossroads_Windows_v114.zip if you offer Windows downloads.
4. **No Render backend files, build/start commands or settings changes are required.**
5. Upload student/CLASSROOM_PLAYTEST_PACK.pdf or the editable Markdown handouts to your classroom site if desired. Students submit reports through your normal classroom channel.
