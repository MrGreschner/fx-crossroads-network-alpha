# FX Crossroads v121

## Hero changes
- Mosaic Tender: primary still summons a tile, and clicking an enemy marks that target for companions. Commands work at full capacity too. Guardian maximum five pieces, with two additional small companions. Merging gives 14 + 3 seconds per additional piece, up to 26 seconds. Scatter splits tiles and grants all of them +35% movement and +40% attack speed for 4 seconds, even if no tile needs splitting. New charged Bubble Bloom special: five bubbles, 9–14.4 contact damage each, 3-second slowing splashes. Works without summons.
- Dust Marshal: pistol rounds look like small pointed bullets, with no orb graphic.
- Reed: Oar Sweep visibly sweeps across its melee arc; tap deals 25, 1.1-second full charge deals 40 and slows struck enemies by 40% for 2 seconds. Each target is hit once per sweep. Final mastery remains River-Reed Rake.
- Frostguard: all four poses rebuilt with mask/cage, leg pads, catcher, blocker, stick and skates. Existing skating controls retained. SVG sources included alongside rendered PNGs and legacy pose aliases.
- Patch: Player Two companions use the targetable companion system, have 45 HP each, spawn separated and repel overlapping companions. Passive and mastery duration adjustments remain supported.
- Clockwork Apiarist: primary cooldown 0.45s, charge time 0.9s, larger amber glow/orbiting charge sparks. Existing full-charge stun retained.
- Stormscribe: primary cooldown 0.45s, charge time 0.85s. Fully charged ball lightning sends 4-damage shocks within 90 reach every 0.25s, capped at three shocks per target per cast. Existing passive cooldown modifier remains.

## Install / deploy
Extract into a fresh folder, open project.godot in Godot 4.5.1, and export Web again for itch.io. If using the downloadable edition, export Windows again too. This ZIP is the editable source project, not a playable web ZIP. No Render room-service files or settings changed.

## Validation
Headless import, new combat/companion tests, prior v120 combat and v118 tutorial-death regressions passed. Rendered training/combat visuals inspected. New tests cover marked target priority, bounded merging/capacity, single-tile haste, bubble damage/slow/expiry, swept oar damage, ball-lightning shocks, Patch separation and targetability, PvP summon destruction and mark snapshots. Real browser/device multiplayer should be checked after export.
