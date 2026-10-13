# FX Crossroads v82 — Practice rivals and ability fixes

## Heroes
- **Burrowick:** two primary swipes, 18 damage each, 0.14 seconds apart. Each successful swipe independently has a 40% chance to apply bleed: 2 damage each second for 3 seconds. Reapplication refreshes the bleed; it does not multiply it. Walking remains locked during the swipes.
- **Nullweaver:** the actual solo special now receives the cursor target, matching its aiming guide. The existing range, wall checks and rotating triangle remain.
- **Kite Corsair:** Windlass Swing now orbits the chosen anchor for 2.2 seconds, carries incoming momentum, accelerates to 480 speed, and releases with tangential momentum. Walls stop travel. Contact damage remains once per enemy.

## Arena practice
Choose **Practice bots: 0–3** before hosting. With bots selected, **Play Solo** starts immediately without needing Render. The three dedicated NPC kits are Sable Voss (ranged skirmisher), Brass Bastion (shield and melee rush), and Cinder Oracle (projectiles and area control). They are practice opponents, not new unlockable player heroes.

Bots occupy fighter seats; they never consume network connections. Eight fighter seats still support eight humans with zero bots, plus a separate spectator host. With three bots, five human fighters and a spectator fill the same arena. For balanced solo teams choose one or three bots; free-for-all supports all three counts. A spectator-only solo exhibition needs at least two bots.

Any match containing bots is practice for its entire duration. Player damage contributes to that hero's mastery, once per confirmed damage total. Arena wins, losses, kills, streaks, trophies, profile records and town-task progress are not awarded. The local scoreboard still shows the current match's combat results. Human-only arena records are unchanged.

Bots react on a short decision interval, lead visible targets imperfectly, keep range or close for melee, separate from nearby fighters, steer around obstacles, dodge approaching shots and escape visible arena floor warnings. Sable Voss in North Gate gains the same shared spacing, steering and bounded leading, plus target stickiness and corrected backline retreat. These are deliberately bounded game AI routines, not machine-learning or a remote AI service.

## Spectator lobby
Selecting Host as Spectator removes the host from fighter slots even before creating a room. A distinct broadcast seat appears at the side. The eight player positions stay available.

## Deployment
This is the editable Godot project, not a ready-to-upload web export. Room-service protocol is **16**. Update the four service files listed in MULTIPLAYER_RECOVERY_GUIDE.md before uploading the matching exported web game. Existing Render settings and URL stay the same. No deployment has been performed for you.

## Validation
Godot ability checks cover the real special dispatch, two swipe damage/bleed behavior, and swing orbit/momentum. Arena checks cover bot solo start, guest roster replication, spectator separation and damage-only progress. Existing eight-fighter spectator and North Gate route checks pass. All 18 Node room-service tests pass, including reserved bot seats and protocol isolation. Lobby and broadcast views were rendered and inspected. Real school-device WebRTC connectivity and sustained browser performance still need a local playtest; automated checks cannot establish those.

## AI reference
Craig Reynolds, Steering Behaviors for Autonomous Characters (1999): https://www.red3d.com/cwr/steer/gdc99/ . The shared combat_brain.gd separates spacing decisions from steering and physical movement. Arena AI logic is in arena_bots.gd; dedicated kits are in content/npc_heroes.
