# v47 — Garrick Runebearer

Hero 30 is **Garrick Runebearer**, a male travelling rune smith with original bearded pixel art, 125 health, 225 speed and no gold cost. All v46 original-hero changes, Iris, Elder guidance and the requested roster order remain.

| Ability | Behavior |
| --- | --- |
| Rune Hammer — primary | Throw a visible spinning hammer, 24 damage, 400 reach and 0.8-second cooldown. Other enemies within 65 units of the hit take 8 splash damage. Walls stop the shot. |
| Threefold Oath — secondary, level 3 | Each use advances one step: **Might** gives +20% damage, **Stride** gives +30% movement speed, **Ward** reduces incoming damage by 35%. Each lasts 4.5 seconds; cooldown is 6 seconds. One rune at a time, with the next rune shown beside Garrick. |
| Purifying Rune — passive, level 5 | Ward activation removes burn, bleeding and poison. It does not heal damage already taken. |
| Triune Verdict — special, level 6 | Mark a point up to 240 units ahead. At 0.45 seconds, a 75-radius hammer seal deals 24 damage and knocks back. At 0.95 seconds, a narrow 250-unit crosscut deals 28 and slows. At 1.5 seconds, a 155-radius final ring deals 38 and stuns for 0.65 seconds. Each strike has a distinct warning shape; wall checks block damage. Cooldown 20 seconds. |

The buff cycle is personal; it does not give teammates his buffs. It is host-authoritative in multiplayer, and a new run resets the sequence to Might. Guard does not permanently stack with itself. Cooldown improvements can shorten the wait, but selecting another rune replaces the previous one.

No new realm or game mode is added in this update. The package includes the entire v46 update and all earlier content. Use v47 as the replacement editable project, then export a fresh Web ZIP for itch.io. No Render change is required, and all players should use the same build.

## Validation

Godot 4.5.1 tests checked buff order, cooldown enforcement, real outgoing/incoming damage, movement increase, expiration, passive level gating, cleansing, hammer impact, all three warned special strikes, death cancellation, run reset and host/guest state. v46 heroes, Rook, school co-op, expert content and Gate Defence regression checks passed. Character Hall text, original art, hammer, verdict effects and rune indicator were rendered and inspected. Physical-phone and live-browser networking remain deployment playtests.

`tools/build_garrick.py` regenerates Garrick's data/art and overwrites direct edits to those generated files. The new styles are listed in `ABILITY_CATALOG.md`.
