# v99 checks

Checked with Godot 4.5.1.

- tests/v99_polish.gd: passed gameplay-only Candle Light bonuses, 3.5s Shell Receipt catch/expiry, compact cat sprites and attached ears, all requested moving trails, idle-bee tracking, one landing puddle per flop, shared 96-entry cap, disabled-actor cleanup and trail/stale-cache expiry. Arena/lobby aura gating passed.
- tests/v98_heroes.gd: passed base/mastery kits, treats, team aura filtering/nonstacking, crit bonus versus chance, projectile bank and host-owned guest combat/movement. Its duration-expiry regression was updated for the requested 3.5s guard.
- tests/v97_refinements.gd and tests/v97_additions.gd: passed prior UI, combat, cosmetics menu, scoreboard, Elder and town/pond checks.
- Native render inspected the Cat, cosmetic styles, idle bees/steam/wing sparks, Scary Face eye beams, and Wick in town without its gameplay aura. No script exceptions in the render run.

Local native/headless checks do not verify physical phones or live classroom networking. The room service remains protocol 26 and unchanged; no Render update is required.
