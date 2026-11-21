# Crossroads V374 — Earned unlocks and champion tactics

## One-time hero ownership reset

All pre-V374 (ownership v1/v2/v3) owned lists are cleared exactly once. Older versions
mixed tried heroes with earned heroes and did not retain evidence that separates them.
This is the announced pre-launch hero ownership reset, not an account wipe. Existing
hero mastery, levels, currencies, items, fish, crops, records, realm clears, friendship,
Studio projects and quest/activity progress are retained. Nine starter heroes remain
available. Existing realm clears still make the relevant champion duel ready; players
do not have to repeat those clears. Completed activity requirements can re-award their
heroes from retained progress. Existing personal-course preparation is retained.

Ownership v4 never grants a hero for recorded damage or prior use. Missing-ownership
legacy profiles likewise start without nonstarter grants. Old imported/cloud profiles
migrate by the same rule. Once a hero is earned under v4, later saves, reboots and
updates retain it. A short migration notice explains the change. Matching network
clients send hero_unlock_epoch=4; the V374 server rejects older/missing epochs before
accepting ownership claims. This is version compatibility within the existing trusted
portable-profile model, not a new cryptographically signed anti-cheat system.

Locked active heroes can be tried in the Training Yard. Their test does not grant
ownership or mastery damage; returning to town uses an owned hero. The general
ownership guard had inadvertently blocked these tests; it now permits only the
isolated practice route. The explicit practice damage guard also prevents a direct
progress callback from counting dummy-test damage. Ordinary gameplay remains gated.

## Champion duels

All 28 current unlock-duel opponents (25 realm champions and 3 personal-duel heroes)
now use a duel-only tactical controller. These changes do not replace the normal
multiplayer bot controller. Fights still use level-10 base kits, ordinary hero health,
damage and cooldowns, no equipment/mastery upgrades, first knockout, and free retries.
No bonus health, damage, hidden attack-speed boost or cooldown bypass is added.

- Sampled perception every 0.22–0.29 seconds, with limited velocity estimates and aim
  error. Committed attack warnings create an opportunity to change direction.
- Real charged attacks hold to their authored full charge duration, including Anjali's
  four-arrow volley. Charging does not perfectly track the player's live position.
- Threat observation before a dodge, one random response roll per observed shot,
  normal 2.5-second cooldown and 0.22-second invulnerability during a smooth 0.26-second
  movement. Clamps, movement locks, stun, transport and other real restrictions apply.
- Blocks and guards use actual abilities and their cooldowns. Defensive abilities can
  be baited. Healing is saved for missing health. Hazard escape also has a reaction delay.
- Hero-specific range changes, setup/follow-up conditions, defensive decisions and
  opening delays. Specials do not immediately fire at round start. Intro displays
  fighting style and Introductory/Challenging/Advanced difficulty.

| Opponent | Fighting style | Tier |
| --- | --- | --- |
| Briar Skipper | Acorn skirmisher | Introductory |
| Recess Warden | Patrol defender | Introductory |
| Sunpetal | Bloom artillery | Challenging |
| Snowdrift | Chilling pursuer | Challenging |
| Tide Keeper | Sluice controller | Challenging |
| Spark Keeper | Relay conductor | Challenging |
| Lockjaw | Clamp hunter | Challenging |
| Echo Dancer | Feint duelist | Challenging |
| Bracken of Moonburrow | Minefield baiter | Challenging |
| Prism Mage | Shard zoner | Challenging |
| Kage Moonstep | Blade ambusher | Challenging |
| Pippa Fernwhisker | Fern anchor | Challenging |
| Velvetwing | Silk trapper | Challenging |
| Chronicle Keeper | Time counter | Challenging |
| Clockwork Apiarist | Hive marksman | Challenging |
| Quarantine Medic | Sustaining brawler | Challenging |
| Tova of Lanternmarsh | Haven footworker | Advanced |
| Hazel Hex | Poison kiter | Advanced |
| Reed of Silverfall | Oar and stone | Advanced |
| Cobbleclaw | Shell counter | Advanced |
| Nera Lockstep | Latchline planner | Advanced |
| Bolt Ironcore | Transforming bruiser | Advanced |
| Molten Pilgrim | Volcanic bastion | Advanced |
| Vesper | Disc and guard | Advanced |
| Veyra Spellthief | Snare punisher | Advanced |
| Mara Dawnblade | Dawn counterguard | Challenging |
| Rune Duelist | Rune closer | Challenging |
| Anjali Dawnbloom | Branch archer | Challenging |

Examples: Kage opens at blade range and closes after the throw; Mara blocks and then
pressures with a charged counter; Anjali plants her return branch and can retreat to
it; Veyra follows her snare with the ledger; Cantor sets a relay before thunder;
Glimmer Mantis remains a course hero rather than a new champion duel; Medic saves
healing for actual damage. Defensive spacing is still beatable through good movement.

## Validation and practical limits

- Migration v1/v2/v3 and missing-owner history: tried heroes do not remain owned, all
  other fields preserved, existing realm readiness and qualifying activity re-awards.
- Real disk reload migrates once; locked-hero Training test and exit stay isolated;
  a newly earned hero persists after another reload.
- All 28 opponents deal real damage and defeat a stationary normal-health starter in
  accelerated combat simulation, using actual kit code. This is a smoke test of
  functional pressure, not a measured human win rate or proof of classroom balance.
- Delayed projectile response, smooth dodge/cooldown/invulnerability, real blocking,
  full Anjali charge, hostile-field avoidance, conditional healing and snare follow-up.
- All 44 authored courses and all seven activity goal regressions; all three personal
  duel knockout awards. Server denies old epoch, unowned join/change and accepts
  matching owned claims/starter. Native duel UI captures reviewed.
- Full source archives match final changed bytes; CRC, no duplicate entries, part
  hashes/offsets and per-file size checks; packaged Web PCK loads changed modules.

Godot4.7.2 locally; pre-existing native shutdown resource cleanup warnings. Actual
classroom/mobile difficulty and live Render deployment need playtesting. Update BOTH
web and server to V374. Existing server/database environment settings stay in place.

## Complete standalone packages

Web: full index.html/engine/WASM/content, pack data split into <=32MiB parts.
Server_Project: full source, art, network service, Dockerfile.network and render.yaml;
no standalone exported PCK and no dependency on older source trees. Extract the
contents into the existing GitHub Desktop checkout, preserve .git/environment/database
settings and Render Dockerfile.network path, commit and push. Editable: full Godot
project, open project.godot. Every individual Web/Server file stays below100MB.
Do not commit the downloadable ZIP archive itself into the server repository.
Complete V373 retained as rollback. The older V372 three-build set was retired after
verifying V373, saving1,041,142,964 bytes; V369 Server_Project and original art/handoffs
and SUBVEIL remain protected.
