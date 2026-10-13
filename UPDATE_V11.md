# FX Crossroads — The Shattered Oath update (v11)

This is the complete editable Godot project, including v10 mobile controls and
all previous gameplay updates. Export Web and upload that exported ZIP to itch.io;
do not upload this source ZIP as the playable HTML game.

## New playable heroes

- **The Crosswind Striker** is an animated soccer ball. Driven Shot is a moderate
  ranged primary (21 damage / 0.7 seconds). Slide Tackle travels only 190 units,
  hits once per target, and has a 3.8-second cooldown. Hat Trick fires three
  spread shots on an 11-second cooldown. Second Wind speeds the primary at Lv5.
- **The Emberwright** wears a welding visor and apron. Forging Hammer is close
  melee (28 damage / 0.8 seconds). Torch Sweep is the secondary: a 150-unit,
  55-degree cone with at most five 8-damage ticks over 0.9 seconds, then a
  4.5-second cooldown. It requires continued aiming and cannot pass through
  obstacles. Damage bonuses are divided across its ticks. Quench Shield reduces
  incoming damage by 65% for 2.2 seconds, with a 12-second cooldown. Tempered
  Plate reduces damage by 10% at Lv5. Its slower movement is intentional.

Their JSON definitions, sprite poses and combat behavior work in solo realms,
practice, PvP, Gate Defence, co-op and Ram Descent. They are free heroes. The
hero list still scrolls, and Warden remains removed.

## The Shattered Oath

Enter from the town realm portal (on the second realm menu page), or select it
in the co-op lobby. You begin in the safe Nexus and use Interact at rifts to
enter four separate chambers within the same world. Health, XP, equipment and
completed seals carry between chambers. You can choose their order.

| Trial realm | Timing puzzle | Guardian and attack |
| --- | --- | --- |
| Briar Reliquary | Staggered thorn gates; generous safe intervals | Briar Matron predicts your position with three root blooms |
| Cinder Causeway | Furnace gates with longer burns | Kiln Knight warns a charge lane, then charges along it |
| Mirrorfrost Gallery | Alternating mirror gates | Mirror Oracle creates six delayed mirror bursts |
| Stormglass Spire | Faster lightning rhythm | Storm Archon warns crossed lightning beams |

Solid barriers force the three-gate crossing. Red/WAIT means the entire strip
is dangerous; green/CROSS is safe. Each crossing has safe gaps between gates,
and traps deal 12 damage with an individual hit cooldown. Dodge invulnerability
can help. A seal requires all ten original enemies AND its guardian to be
beaten. Cleared seals restore 30 health to living players. Rifts return to the
Nexus, where the fifth rift opens only after all four seals are claimed.

### The Gilded Usurper

The final boss cycles three attacks:

1. Summon oath shades, with a six-shade cap.
2. **Soul Tax:** a purple, clearly labelled delayed circle at the player's
   position. A hit steals gold and XP. Enough hits lower your current level,
   locking secondary/special and passives until the required level returns.
   Successfully dodging with invulnerability also avoids the XP theft.
3. A warned three-lane fan of gilded blades.

Its first defeat creates **three** smaller Usurpers. Each of those creates
**three** more: nine final fragments, thirteen boss bodies across the encounter.
All boss fragments must die before victory. Stolen XP and coins return after
that final victory. XP theft affects the current run, not persistent cosmetics.
Previously earned stat rewards cannot be farmed by repeatedly losing/regaining
levels. Interact at the final throne to claim the clear and results.

Co-op uses the same puzzle, boss progression and host-authoritative XP theft,
with enemy health scaling to party size. Rifts move individual players, allowing
teams to divide the trials or travel together.

## The Lantern Marsh

An independent realm with a lantern-lit causeway, reed beds and luminous groves.
Its original enemies are armoured **Lantern Crabs**, plant-like **Reed Stalkers**
and ranged **Wick Wisps**. The **Bellroot Colossus** warns a ring of bell blooms
and summons a limited number of reeds. Its terrain, props and enemy silhouettes
are distinct from the other realms. It is available for solo and co-op play.

## First-run welcome, rewards and student ownership

A small town checklist guides new players through choosing a hero, landing
three training-yard hits and entering Whispering Grove. It disappears when
complete. The **Your Journey** board in southern town (or T on desktop) allows
skipping the checklist and equipping unlocked ribbon colours and titles.

Cosmetics have no stat effects and persist locally on that device/browser:

- First Footsteps: finish the welcome checklist.
- Grovekeeper: clear Whispering Grove.
- Lantern Bearer: clear Lantern Marsh.
- Oath Restorer: clear Shattered Oath.
- Team Anchor: perform three teammate revives.

Equipped ribbons/titles appear on the hero; multiplayer sends them to teammates.
The Character Hall automatically displays portraits from the hero registry, and
realm flags grow with the realm list. The **Student Creators** board credits the
school programs. Edit **content/creators.json** to add real student names and
contributions; no invented student names are included.

## Combat, revives and results

Short generated sound cues distinguish swings, projectiles, torch flames, hits,
damage and rewards. Existing impact flashes/damage numbers remain. Trial boss
attacks have explicit warnings; multiplayer enemies now wind up before attacks.

In co-op, Descent and multiplayer Gate Defence, zero health creates a 25-second
downed window. A living teammate within 110 units holds **Interact/E for two
seconds** to revive, restoring 35% health with two seconds of protection.
Changing rescuer or releasing/going out of range resets progress. Healing
abilities cannot bypass a revive. Defence respawns after the downed window;
co-op/Descent can restore fallen heroes at the next completed stage. A complete
party wipe ends co-op/Descent. Solo Defence retains its normal respawn.

Results credit actual capped damage and healing, revives, defence kills and
guard upgrades. PvP stays respawn-based: FFA ends at ten player eliminations,
teams at fifteen combined eliminations, or either mode after five minutes.
Enemy kills do not count toward those arena victory scores. The results panel
appears before returning to town or starting again.

## Teaching and extension

- Hero stats/abilities: content/characters/soccer.json and welder.json.
- Realm data and trial descriptions: content/regions/shattered_oath.json and
  lantern_marsh.json.
- Editable layouts: scenes/realms/shattered_oath.tscn and lantern_marsh.tscn.
- Enemy definitions: content/enemies/*.json; new enemy sprites have unique
  silhouettes and all four poses under assets/.
- Shared puzzle/phase logic: scripts/realm_trials.gd.
- Welcome, achievement and audio logic: scripts/journey.gd.
- Art regeneration: tools/build_expansion.py (requires Pillow). This rebuilds
  the shipped generated assets/layouts; back up student edits before running it.
  Existing creator credits are preserved.

## Validation and release check

Godot 4.5.1 headless import/runtime checks cover all eleven heroes in all four
multiplayer modes; mobile multi-touch and hero scrolling; trial walls, locks and
seals; all guardian warnings; 1-to-3-to-9 splits; XP loss/restoration; capped
healing and held revives; and JSON host/guest state transfer including rifts,
fragment generations, downed state and results. These checks passed.

Physical phone layout/performance and live WebRTC connections still need browser
playtesting. Before class, export Web, replace the itch.io playable upload, then
try a landscape phone and a two-PC room. This larger content update has not been
balance-tested by students; health, damage and trap timing remain editable.
