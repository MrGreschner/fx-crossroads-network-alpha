# Crossroads V372 — Seven activity hero unlocks

This pass adds Aurel, Ripplejaw, Mosaic Tender, Crossroads Teacher, Hearth Herald,
Star Navigator and Cindervane to the ownership system, alongside the 25 V371
realm champions. The nine starter heroes remain free. Other not-yet-implemented
quest and event unlock routes remain available until their future passes.

| Hero | Permanent unlock |
| --- | --- |
| Aurel | 100,000 eligible account combat damage; no dummy/AI-practice/unofficial damage |
| Ripplejaw | 70 species discovered; kept and released catches count once per species |
| Mosaic Tender | Harvest 3 different crops in the Seedhouse greenhouse |
| Crossroads Teacher | Guided Hero Workshop lesson plus a successful 10-second test, 3 hits, a primary cast and a matching project revision |
| Hearth Herald | Clear Descent floor 50, including the boss |
| Star Navigator | Clear 2 distinct realms started at night, and catch 20 fish at night |
| Cindervane | Six consecutive realm clears, with 4 different realms, without dying |

Challenge Lodge now has Hero Goals beside Hero Challenges. Character Hall shows
locked heroes and current goal progress, with a View goal action. Awards unlock
automatically, persist in portable profiles and show a short notification.

Teacher lesson uses the current draft and does not overwrite it. Begin the lesson,
name and describe the hero, change primary mechanics, then Playtest and Finish &
report. Renaming/recolouring the attack alone does not satisfy the mechanical edit.
No publishing, account, classroom enrolment or teacher approval is required.

Night follows the existing town clock, 21:00–06:00. Night-start realm clears and
fish catches accumulate across sessions. A six-win rolling window checks Cindervane's
four-realm diversity. Your own zero-health/downed event, defeat, abandoning a started
run, replacing an unfinished run, or practice continuation breaks that streak.
Town visits and logging out between completed runs preserve it. Reconnecting to the
same multiplayer match keeps its original night flag and cannot count its result twice.
Training, unrelated activities and champion duels do not add streak wins.

Historical migration: existing played heroes remain owned. Known legitimate damage,
positive-count fish discoveries, retained harvested produce and completed Descent
floors count. Starting/seen seeds and zero-count fish previews do not count. Old
night and diverse deathless wins are not inferred from insufficient history. New
ownership schema v2 still imports V371 profiles. Goal state is validated and included
in profile exports and practice-continuation rollback. Hearth Herald lore now places
her in the cave hearths instead of Ember Quarry.

Update both Web and Server_Project to V372. Server ownership claims now cover all
32 managed heroes, including random Arena picks. This uses the existing trusted
portable-profile model; it does not introduce a signed anti-cheat account ledger.

Full delivery: Web ZIP is the browser build; Server_Project ZIP contains the entire
source/artwork/server service and Dockerfile.network; Editable ZIP contains the full
Godot project. Extract Server_Project at your GitHub Desktop repository root and
replace matching files, then commit/push. Keep .git, Render environment/database
settings and the existing Dockerfile.network path. No local build script required.
No contained server or web file exceeds 100,000,000 bytes. Web data parts <=32MiB.

Validation: new goal/migration/schema boundaries; real fishing completion and harvest
hooks; exact damage and floor-50 boundaries; day/night and diversity; real solo start,
win, loss, town return and practice-continue paths; actual editor/test-runtime lesson
completion and permanent save; server ownership restrictions for activity heroes;
all 25 V371 champion eligibility/loss/permanent-victory/rematch regressions; actual
Godot screen captures; ZIP CRC/hashes and per-file size checks. Godot 4.7.2 used here.
Live browser/Render/Docker 4.5.1 deployment and classroom balance remain untested.
Existing native shutdown resource-cleanup warnings remain.

Remaining work: authored activity quests for Wanderlight and Lyra, Paradox Regent's
time trial, the remaining thematic hero quests, and event ownership rules.
