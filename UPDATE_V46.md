# v46 — Original hero identities and Iris Chalkbinder

Young Ram, Dribble, Living Book and Crossroads Cat have individually drawn attack poses and different shared attack effects. Their primary effects are horn impacts, a squash-and-bounce ball, a paper-edge slash and three curved claw marks. These visuals and hit logic work in solo and multiplayer.

## Revised abilities

| Hero | Change |
| --- | --- |
| Dribble | Primary damage is 29. Triple Bounce now moves Dribble himself smoothly between up to three distinct targets; no projectile. 28 damage per target, 5-second cooldown. First target within 350; later targets within 260. Walls stop movement, and he remains vulnerable. |
| Living Book | Paper Cut has a visible sharp page edge. Hold secondary (right mouse or touch Secondary) to open the Book and release seeking paper pages every 0.22 seconds, 11 damage each. While open it cannot move, dodge or cast other attacks, and takes 30% extra damage. Releasing closes it immediately; restart cooldown is 0.35 seconds. Stun, death, changing heroes and missing remote input heartbeats also end the channel. |
| Crossroads Cat | Whirlwind Spin now visibly sweeps around over 0.6 seconds. Its moving sector hits each enemy once for 43 damage instead of damaging the whole circle immediately. The Cat has a curled spinning pose. |
| Frostguard / Quarantine Medic | Primary damage is 29 for both. |

The Elder Ram now explains Character Hall, training, realms, school routes, co-op revives, Arena, Gate Defence, Ram Descent, Wayfarer quests, level milestones, matchmaking and controls. The previous roster order remains: Emberwright, Quarantine Medic, Star Navigator.

## Hero 29 — Iris Chalkbinder

Iris is a travelling tutor with enchanted chalk: a tactical floor-control mage with 105 health and 235 speed.

- **Chalkstroke:** draw a line up to 250 units over 0.45 seconds. Each enemy touching it takes 16 damage once. Lines last four seconds; keep up to three. 0.7-second cooldown.
- **Erase & Release:** consume your lines into two seeking shards per line, 12 damage each. With no lines, send one shard. Seven-second cooldown.
- **Living Blackboard:** a 300 × 220 grid ahead lasts four seconds. Enemies inside move 35% slower and take 7 damage every half-second. 18-second cooldown; walls block its damage.
- **Second Draft:** at level five, erasing a line restores three health to Iris.

This update focuses on the existing game styles and hero combat. No additional realm or game mode is added. All 21 regular realms, the quest expedition and v44 schools remain.

## Verification and deployment

Godot 4.5.1 tests cover original primary hits, exact 29-damage values, three distinct bounce targets, collision barriers, held page cadence and impact damage, vulnerability, release/stun/death/input-timeout cleanup, staged Cat sweep hits, Iris line limits/erase/heal/grid behavior, and authoritative co-op input/state. Previous school solo/co-op, expert realm, Rook, results and Gate Defence checks passed. Character Hall text, the Elder guide, original attack poses, Book open pose, Cat sweep and Iris's grid were rendered and visually inspected.

Physical phones and live browser-to-browser networking still need a deployment playtest. Extract this source ZIP, open `project.godot`, allow asset import and press F5. Export a new Web ZIP for itch.io. All multiplayer users should use this build. No Render change is required.

`tools/build_v46_heroes.py` is the repeatable data/art authoring source. Rerunning it overwrites its generated hero files and images. See `ABILITY_CATALOG.md` for the new engine styles and student fields.
