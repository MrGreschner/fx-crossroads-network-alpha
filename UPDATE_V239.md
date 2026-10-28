# Crossroads V239 — Leech Charm rebalance

Leech Charm now restores 8 HP per enemy KO credited to its holder, capped at maximum health, instead of healing 6% of damage dealt. Ordinary hits no longer trigger charm healing. Its price and artwork stay the same. Item IDs remain stable, so previously purchased charms use the new effect.

Applied to solo enemy defeats, authoritative co-op/Cave Descent enemy defeats, PvP hero KOs and credited Battleground soldier KOs. Converted allies, nonlethal hits, revived/intercepted defeats and already defeated targets do not award charm healing. Duplicate charms cannot stack the effect, dead holders cannot be revived by a delayed KO, and guest clients cannot award their own heals. Normal healing-reduction modifiers still apply. Other heroes' healing passives and other lifesteal items retain their separate effects.

The item description, passive-slot handling and purchase duplicate rules match the new effect. V237 performance work and V238 Cave Descent loadout carryover are retained.

Validation: 23 focused headless checks passed, covering actual solo/co-op damage and KO paths, capped healing, no-item/duplicate/converted/dead cases, passive use, guest authority, PvP and Battleground KO handling, unrelated siphon lifesteal and server compilation. The existing fixture reports retained ObjectDB/resource references at shutdown; no in-session script errors occurred in the successful checks. Live browser/device playtesting remains recommended.

Deploy Server_Update first, then replace Web. No database migration or record reset is included. This update has not been deployed by this task.
