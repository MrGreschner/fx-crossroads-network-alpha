# v78 — Burrowick and Nullweaver

## Town
- Removed the three directional road boards; building labels remain.
- Moved the North Gate's two standing ram guards outward and north, clear of its label.

## Burrowick — quarry gopher
Tunnel-slide movement alternates 0.30s underground with a 0.42s surface pause. Average speed remains 230. Moving underground avoids damage; stopping does not grant immunity. Attacks stop movement and expose the hero. Pounce is an intentional underground attack with a short immune travel phase.
- Quarry Claws: close melee, 25 damage, 0.7s cooldown.
- Pop-up Pounce: burrow along a clear path, 35 splash damage and 1s stun; 7s cooldown.
- Cave In: warn, then collapse the last four completed tunnel segments, 65 damage per foe once; 15s cooldown. No stored trail falls back to a short crack ahead.
- Packed Earth: 12% protection for 2s after Pounce, unlocked at level 5.
- First mastery: wider Pounce and longer stun for reduced damage.
- Final mastery: replace trail-based Cave In with one longer aimed Faultline, reduced damage and longer slow.

## Nullweaver — rift tailor
Fragile and demanding: place two pins around enemies rather than simply aiming at them. The connecting seam deals damage; rotate it through enemies and predict where triangle edges will land.
- Stitch Reality: tiny 18-damage pin impact, connecting seam 25.2 damage. Two pins maximum; next replaces oldest. 0.85s cooldown.
- Quarter Turn: rotate the seam by 90 degrees, 42 damage once per foe; 5s cooldown. Needs two pins.
- Impossible Hem: three warned triangle edges fire sequentially, 36 damage per edge; 14s cooldown. The centre is safe.
- Needle Frost: hits slow by 20% for 1s, unlocked at level 5.
- First mastery: wider sweep with reduced damage.
- Final mastery: replace triangle edges with three smaller delayed rift bursts; easier aim, lower potential damage.

Both heroes include matching idle/walk/attack pixel art, titles, critical milestones and mastery tuning. Shared combat supports solo, co-op and arena with host-owned damage and serializable effects. Effects and tunnel history are bounded.

## Install
Includes the complete v77 update. Use room service version 14 (unchanged from v77): `npm install`, then `node server.mjs`. Follow MULTIPLAYER_RECOVERY_GUIDE.md, and export/upload a fresh v78 Web ZIP for itch.io. This archive is editable source, not a Web export or compiled Windows executable. BUILD_WINDOWS.cmd builds Windows and optionally Web on your PC.

## Validation
Run tests/v78_heroes.gd and tests/v78_multiplayer.gd with Godot headless, then the v77 party/arena and v75 multiplayer regression checks. The room service's Node tests verify lobby and invitation handling. Native rendering checks verify sprites, town labels and combat effects. Live school-device multiplayer remains a final deployment check.
