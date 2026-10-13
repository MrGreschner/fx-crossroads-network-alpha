# Authoring hero mastery

Mastery is a separate top-level object in each hero JSON. It is not the level-five passive, and does not replace the existing level-eight/ten in-run choices.

```json
"mastery": {
  "title": "Horn Champion",
  "technique_requirements": {"clears": 3, "distinct_realms": 2, "damage": 10000},
  "title_requirements": {"clears": 6, "distinct_realms": 3, "damage": 20000},
  "technique": {
    "name": "Longhorn Rush",
    "ability": "secondary",
    "description": "Charge farther and faster, but deal less damage.",
    "multiply": {"range": 1.35, "speed": 1.15, "damage": 0.8},
    "set": {}
  }
}
```

The shared engine copies effective attack stats at cast time. `multiply` adjusts existing numeric fields; `set` supplies explicit values. Give every advantage a real disadvantage, and write the actual numbers clearly. Use fields the attack implementation actually reads; adding a new field does not create behaviour by itself. For example, changing `count` on a hard-coded three-hit attack requires code support. A genuinely new spell needs a supported combat style, just as before.

New supported variations: `page_channel` reads `channel_move` and `page_interval`; `manual_mines` reads `timed_mines`, fuse `duration`, and caps live timed mines at three; `tea_shot` reads `tea_element: "burn"` to exchange its poison for burn. Existing channel vulnerability remains. Timed mines explode through ordinary ring damage and respect obstacles. Tea secondary/special remain unchanged.

`legacy.gd` owns progress, profile I/O, town requirements, tuning, and the journal. `object_combat.gd.effective_stats` applies authored techniques; hero source data is never modified in place. Both game scenes use this path. Solo special casting now uses effective stats too. Multiplayer sends one bounded build and includes it in snapshots.

Portable format version 1 contains a `progress` object and an allowlisted `saves` dictionary. Never accept arbitrary paths from imported JSON. Imported profiles replace, rather than merge. Teacher progress has a separate normal backup. Profile files can be edited by users; these client-side saves are not cheat-proof.

Run `tests/v66_legacy.gd`, `tests/v66_profile_restore.gd`, and relevant combat regressions before shipping a changed technique. Add a meaningful test if a variation introduces new behaviour. The current tuning maximum is four equipped points with two per track; increase only after balance testing.


## v68: final alternate spell and crit milestones
Every new student hero needs **two mastery designs**: the earlier technique, then a final alternate with its own readable attack animation. The final replaces a different ability button from `technique.ability`; do not rewrite the same attack twice. The alternate should solve a different problem and give up something meaningful: range versus damage frequency, a line versus a circle, delayed bursts versus instant hits, or ground control versus movement/defence.

Add these fields inside `mastery`:
```json
"final_requirements": {"clears": 12, "distinct_realms": 6, "damage": 85000},
"final_technique": {
  "name": "Faultline Rush",
  "ability": "special",
  "description": "Trade the close stomp for a charged narrow faultline: 70 damage, 0.7s stun and 360 reach; 10s cooldown.",
  "attack": {
    "name": "Faultline Rush", "style": "master_lance",
    "damage": 70, "cooldown": 10, "range": 360,
    "width": 70, "charge": 0.7, "duration": 1.5,
    "stun_duration": 0.7, "color": "#d8b17b"
  }
},
"crit_milestones": [
  {"clears": 3, "chance": 0.02, "bonus": 0.2},
  {"clears": 6, "chance": 0.04, "bonus": 0.4},
  {"clears": 9, "chance": 0.06, "bonus": 0.6}
]
```
The `attack` is a complete replacement, not a partial modifier: supply its name, style, damage, cooldown, range/radius and all fields required by that style. Tuning still applies afterwards. The first technique and final alternate can be equipped together because they affect different buttons. Robot saw-form Shock Stomp remains its transformation attack while transformed.

### Six new reusable attack and animation patterns
| Style | Behaviour | Fields and balance notes |
|---|---|---|
| `master_fan` | Staggered sweeping arcs; each target hit only once per cast | `range`, `count` 1–5, `charge`, `duration`; damage is once per target, not per drawn arc |
| `master_lance` | Visible charging line then a piercing lane hit | `range`, `width`, `charge`, `duration`; duration must exceed charge |
| `master_sigils` | Warning circles placed around the aimed point, then staggered blasts | `range`, `radius`, `count` 1–5, `spacing`, `charge`, `duration`; overlapping blasts can each hit, so divide the damage budget |
| `master_fountain` | Stationary field that pulses damage, ally healing and status | `range`, `radius`, `duration`, `heal`; damage and healing happen every 0.5s, so a 3s field has six pulses; no enemy healing |
| `master_pincer` | Two curved wings travel out for 0.8s and return for 0.8s | `range`, `width`, `duration` at least 1.6; one hit per enemy per leg, shared across both wings; damage can total twice the listed amount |
| `master_chain` | Delayed strikes link up to five nearby visible enemies | `range` per link, `count` 1–5, `duration` at least 0.25 + (count−1)×0.2; each selected target is struck once |

All support `stun_duration`, `slow_duration` with speed multiplier `slow`, and the usual burn/bleed/poison duration and damage fields. Walls block hits. Ground attacks search backwards along the aiming line if a wall blocks placement. Effects are capped and expired; guests render snapshots while the host alone applies combat results.

Graphics: each pattern includes its own telegraph and active animation. Pick a colour fitting your hero. For custom student art, supply optional `visual_texture: "res://assets/my_final_spell.svg"` (PNG works too); it is cached and drawn as an emblem at the attack’s visible point (28px on returning wings, 36px on sigils, 48px on other effects). Edit `scripts/mastery_combat.gd` for a fundamentally new movement/animation pattern rather than adding unimplemented JSON fields. Keep target boundaries visible under your art.

Crit is automatic at the authored clear thresholds, not an in-run level unlock. At most three tiers are supported; chance is bounded to 6% and bonus to 60% in shared combat. The shipped milestones have average damage gains of 0.4%, 1.6% and 3.6%. Crit rolls affect positive hero damage, including repeated attack/status hits, and never healing or enemy attacks. A CRIT label signals a successful roll. Personal profile export/import retains the final equip choice; old profiles begin with it unequipped. Teacher testing unlocks both techniques and the highest crit tier without overwriting normal progress.

See `FINAL_MASTERY_CATALOG.md` for all 43 designs. Validate new heroes with the v68 combat checks and the v66 profile/mastery regressions. Try the original and alternate at the same level and inventory; a late unlock should offer a new play style, not invalidate the original.
