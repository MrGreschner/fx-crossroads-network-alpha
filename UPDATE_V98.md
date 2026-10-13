# FX Crossroads v98 — two new heroes

All v97 changes are included. The roster now has 74 unlocked heroes, with authored numbering preserved and these two added at 73 and 74. Both support role filters, lore, compact ability cards, profiles, mastery titles, two alternate techniques, critical milestones and tuning sliders.

## 73. Wick-o'-Wisp

A jack-o'-lantern from Lanternmarsh's autumn festival; control/ranged support. 105 HP, speed 220.

- **Cinder Candy:** a visible fireball hits for 20, then burns for 2/sec for 3s. Stops at its first target or wall. Cooldown 0.85s.
- **Scary Face:** a forward fan, reach 170, stuns visible enemies for 1.1s, followed by 35% slow for 3s. Foes behind it and through walls are unaffected. Cooldown 7s.
- **Trick or Treat:** 20 treats lob all around over 2s. Each lands for 6, bounces once for 6 more, then opens a small three-second patch. Flavours: slow, poison, burn, shock or allied healing. Fields use icons as well as colour. Cooldown 22s. Harmful effects refresh on enemies remaining in the patch; healing never helps rivals.
- **Candle Light (Lv5):** three rotating overlapping circles boost allied healing received by 15% and existing critical bonus damage by 50%. Does not grant crit chance. A normal +60% critical bonus becomes +90%, rather than multiplying the entire hit by 1.5. Auras do not stack.
- **First technique — Lantern Lance:** heavier, longer-reaching fireball; slower shots and weaker burn.
- **Final technique — Generous Goodies:** fewer treats, half landing damage, only healing/slow fields.

The aura is useful without mastery for received healing, while the critical benefit requires an earned critical tier. Small integer healing amounts round to the nearest available health point in multiplayer.

## 74. Cobbleclaw

A small river-stone crab from Silverfall Reach; melee guardian/support. 145 HP, speed 195, a gently swaying scuttle.

- **Pincer Ledger:** two quick short claw fans, 14 damage each. Cooldown 0.85s.
- **Shell Receipt:** brace for 2.5s with 50% damage reduction; catch up to four hostile projectiles at the shell. Banked shots last 12s. Cooldown 8s.
- **Crosswalk Crush:** wall-safe scuttling rush, once-per-foe 36 damage, push and slow. Finish by spending caught shots on a fan of 12-damage stone shards. Cooldown 14s.
- **Shell Ledger (Lv5):** each banked shot grants 3% damage reduction, up to 12%. Spending or expiry removes this bonus. Existing damage-reduction HUD/indicator includes it.
- **First technique — Heavy Accounts:** heavier, slower claws with longer reach.
- **Final technique — Pebble Nursery:** replace shell-catching with a four-second stationary healing/protective refuge. Consumes banked shots to enhance healing.

## Implementation and teaching

The new reusable styles and passives are documented in ABILITY_CATALOG.md. Editable procedural sprite generation is in tools/build_v98_heroes.py. The shared v98 combat module handles wall checks, authority-owned hits/movement, capped effects, expiry and network snapshots. Existing room protocol 26 and room service files are unchanged.

See DEPLOY_V98.md and RELEASE_CHECKS_V98.md. This archive contains editable source, not a pre-exported browser build.
