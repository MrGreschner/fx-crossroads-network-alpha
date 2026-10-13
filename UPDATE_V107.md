# v107 — Summoned minions can be fought in PvP

Dribble's older Teammate summons were stored in the guard list, outside the shared attack target registry. They now have stable target IDs, join the same enemy targeting lists as newer summons, and can take melee, projectile, area and status damage. Lethal damage immediately removes the minion and its status effects. Team summons reject friendly fire. Defeating a minion does not count as defeating a player hero.

The shared target list covers chain/fork attacks and charge collisions as well. Summon health and owner are included in host snapshots, and a small health bar shows remaining HP on host and guest screens. Only the host changes combat health.

Regression checks: actual Dribble summon cast; actual basic melee damage; projectile collision; AoE; poison; allied protection; guest mutation rejection; lethal cleanup; snapshot health/ownership; Mosaic and Apiarist summon deaths. Prior Game Dev and arena lobby checks also run. These are local Godot checks, not a multi-PC network/hardware certification.

All 74 heroes and v106 Windows download menu/build tools remain. Re-export the v107 Web build for itch.io, and rebuild Windows v107 if offering that download. No room-service changes or Render redeploy needed (protocol remains 28). The Windows output is now exports/FX_Crossroads_Windows_v107.zip. Follow WINDOWS_BUILD_GUIDE.md.
