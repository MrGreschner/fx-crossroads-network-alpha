# V289 — Gladiator arenas: gates and groves

Arena enemies use their body attack pose for windups. The orange engagement circle/exclamation and its duplicate orange pulse are removed from all arena maps. Attack timing, hitboxes and damage remain. Environmental hazard tells and healing indicators remain visible.

Wildbloom Glade grows from eight trees to69–74in the three tested match seeds. Seeded groves use existing tree artwork at varied sizes with trunk collision. The original four trees obstructing the two broad crossing clearings move to their flanks. Hero respawns, creatures and fireflowers use clear floor. Geometry and spawns remain deterministic between host and guest for the same seed.

Clockwork Crucible gears charge broad paired lanes or a central cross every five seconds. Amber outlines/running energy give1.7seconds warning. Blue lightning and sparks mark the same damaging floor for one second. A hero takes at most one18damage hit per overload; dodge immunity still applies. Compared with the old single140px instant stripe, two240px lanes cover substantially more of the map while leaving clear escape areas. The source gears light up and spin faster during the event.

All17Shifting Labyrinth doors follow staggered14second cycles: open for7.5seconds, warning/closing panels for1.5seconds, blocked for5seconds. Approaching a closed gate no longer opens it. An actor standing in the aperture when it closes is moved a short distance to a clear side. Heroes, guards and creatures share this handling; guests receive the authoritative gate state. Chamber ambushes remain but no longer override door schedules. All creatures, including flying ones, use maze navigation and swept body collision; closed gates and permanent walls also block projectiles. Waiting for a gate to open lets you cross and fight beyond it.

Native verification:1222new arena checks,66variant regressions,44objective checks,48Shatterfloor checks and161retained Cave Descent checks pass (1541total), underGodot4.6.3. Drawing callbacks ran headless; visible/browser/co-op combat playtesting remains pending. Target4.5.1unchanged. Web/Server are incremental candidates from verified V288, not fresh exports. Nothing deployed, deleted or reset. Previous V288 Cave changes and actor art are retained.

Restore all four V278 base parts, then ONLY the FINAL cumulative V289 RecoveryDelta. The early Working Recovery is an unfinished noncumulative overlay over exactV288. V288 remains the rollback; exactV281and its four bases remain a permanent LegacyHistory dependency.
