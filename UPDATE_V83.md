# FX Crossroads v83 — AI difficulty and three-lane defence

## Host options
Before creating a room, choose **Practice bots: 0–3** for Gladiator Arena and **AI: Medium / Hard**. The AI difficulty selector is also available for North Gate. These settings are fixed for the room; leave it to change them. Both settings replicate to guests and survive room-service reconnection.

Medium uses a 0.36-second decision interval, more forgiving aim and six-second dodge recovery. Hard uses a 0.18-second interval, stronger target leading, smaller aiming error and 3.5-second dodge recovery. Neither setting increases health or attack damage. Arena bot matches still grant hero damage mastery only: no PvP records, trophies or town-task credit.

## North Gate
- Maximum **three human players**, including late join requests. Arena, Descent and co-op realm limits are unchanged.
- One enemy hero per player: Sable Voss alone; add Brass Bastion for two players; add Cinder Oracle for three. Each uses a separate lane, independent kill XP, leveling and respawn timer. Rival heroes enter from wave 3, as before. Their number adapts when the party changes.
- Sable keeps ranged pressure, snares and crossfire. Bastion closes for hammer hits, braces against damage and rushes into a telegraphed stomp. Cinder fires projectiles and warns before explosive burning zones. Secondary/special moves unlock as these NPCs gain levels. Enemy hero health is not additionally multiplied by party size, because extra party members now add extra enemy heroes.
- Allied marching guards move at **105 instead of 165**, about 36% slower. Summoned hero companions are unchanged.
- Wave 1 starts immediately after the visible match countdown. Wave 2 follows after 12 seconds instead of about 25.
- The first two waves get **double marching speed for eight seconds**. The boost is suppressed near players, guards or an outpost so it accelerates the approach without doubling combat movement. Enemies still spawn at the original far entrances and cannot bypass the first outpost.

## Deployment
Use the included **room service v17** together with this build. Replace rooms.mjs, server.mjs, package.json and package-lock.json in the existing Render repository; existing start/build commands and service URL stay unchanged. See MULTIPLAYER_RECOVERY_GUIDE.md. Then export this Godot project for Web and upload that export to itch.io. This ZIP is editable source, not the playable web export. Nothing has been deployed automatically.

## Checks
Godot tests cover one/two/three-player rival counts, independent leveling and respawning, distinct primary attacks, guard speed, the opening-wave boost and expiry, difficulty synchronization, arena practice progression and eight-player spectator regression. Twenty room-service tests pass, including a rejected fourth North Gate late join and unchanged caps for other modes. The updated lobby was rendered and checked. School-device networking and gameplay balance still benefit from a classroom playtest.
