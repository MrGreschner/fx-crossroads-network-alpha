# v77 — Pick your party, choose your arena

Includes all v76 tutorial, presentation, audio, recognition and connection recovery changes. Use this release instead of deploying v76 first.

## Gather Your Party
- **My hero** is a dropdown in match settings. Change heroes while waiting without leaving the room. The walking portrait and host-owned hero/build assignment update together. Hero switching is locked during a battle.
- **Public Rooms** replaces the Join Random button. A scrollable browser lists compatible public rooms waiting to start, host names, mode and occupancy. Arena entries also show map, rules and starting level. Select a room and press **Join selected room**. Refresh is automatic every five seconds, or manual. Private, full, offline-host and active rooms are excluded; an empty list says so clearly.
- Code entry is now **Join / Request**. Waiting rooms join normally; active Defence/Descent rooms send a request to the host. Arena/co-op realm rosters remain locked mid-match.

## Quick arena rounds
**Opening Act defaults OFF:** every player begins at level 10 with secondary, passive and special available. Turn it ON for the previous level-one progression. Host settings apply to everybody, including randomly assigned heroes. Existing no-items/food and random-hero rules remain available.

Five maps are selectable (the request described five despite saying four):

| Map | Size | Feature |
| --- | --- | --- |
| Crossroads Coliseum | Original large arena | Previous layout and enemy waves |
| Sinking Sands | Small, 2400 × 1800 | Three visible quicksand pools, 45% movement reduction |
| Stormcoil Pit | Small, 2400 × 1800 | Three stalking drones; bolts every six seconds, six bolts per cycle; eight-second orb phase with strong slow and 1 damage per 0.2 seconds. Phases stagger by 12 seconds. |
| Wildbloom Glade | Medium, 3200 × 2300 | Flowers grow temporarily and shoot fireballs; six starting enemies and two larger minibosses (one melee, one ranged). |
| Clockwork Crucible | Small, 2400 × 1800 | Alternating floor-strike corridors, warned for 1.2 seconds before 18 damage |

Hazards are neutral: they can hurt either team. The host owns hazard timing and damage; guests receive compact hazard state. Flower/projectile counts are bounded. Forest miniboss kills are NPC kills, not PvP eliminations. Arena results/streak rules are unchanged.

## Inviting a friend during solo survival
Choosing **Play Solo** now prepares a private online room for Defence or Descent and then starts the game. The **Invite • CODE** button shows the instructions. A friend enters the code, requests admission and the host presses **Accept** on the small request panel. Requests expire after 30 seconds; parties still cap at four.

An approved newcomer chooses their own hero and enters at **level 1, zero XP**, with brief spawn protection. The host's match ID, health, enemies, floor/wave and upgrades are preserved. The arriving client receives the current authoritative state, not a restart. Later progression follows the normal shared adventure rules; starting at level 1 does not prohibit gaining shared XP afterwards. Existing enemies are not rescaled mid-fight; subsequent defence waves use the current party size.

If the service cannot be reached within eight seconds, Play Solo falls back to offline solo. No invite code is available in that session; return to the lobby to retry online. Full host crashes still require a restart; v76 connection recovery remains for brief interruptions.

## Mastery sliders
The three playstyle axes now range from **−2 to +2**, with zero neutral. Each step away from the centre costs a point, in either direction; moving back refunds it. The existing cap remains four equipped points, maximum two per axis, up to six earned.

- Power: each positive step gives +4% damage / +5% cooldown; negative steps give −4% damage / −5% cooldown.
- Vitality: each positive step gives +5% health / −3% movement; negative steps give −5% health / +3% movement.
- Guard: each positive step gives −4% damage taken / −3% attack; negative steps give +4% damage taken / +3% attack.

Existing positive investments are preserved. Profile import/export and multiplayer sanitization accept signed values and enforce the absolute point budget. Techniques, crit milestones and titles are unaffected.

## Healer-house respawn
Respawning checks the proposed position and movement clearance in all four directions. If scenery occupies the old point, it searches nearby clear space before placing the hero. The chosen hero is retained.

## Deployment and validation
**Game protocol 14 + room service version 14.** See MULTIPLAYER_RECOVERY_GUIDE.md. Build/start commands and service URL remain the same. Export a fresh v77 Web build; this archive is editable source, not a playable Web export or compiled Windows EXE.

Focused Godot checks cover all five arenas, starting-level rules, safe spawns, map snapshots, quicksand/orbs/flowers, hero changes, approved late-start state without host reset, battle hero locks, signed mastery budgets and healer escape clearance. Existing lobby, multiplayer, recovery, mastery, UI and town checks are rerun. Node tests cover public visibility, version matching, approval authorization, request expiry/capacity and real WebSocket resume routing.

Still playtest two real school-network devices and iPhone Safari: actual WebRTC transport, touch dropdowns/sliders, join approval during a busy wave, arena hazard feel and difficulty balance.
