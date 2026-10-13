# v112 — Earthquake, Storm Circuit and Hearth Herald

## Young Ram
Earthshaker no longer hits instantly for 85 damage. It leaves a fixed 155-radius earthquake for three seconds, dealing six pulses that total 85 base damage against a foe who stays inside. Foes in the circle slow by 65%; leaving avoids later pulses. Allies are unaffected and walls block hits. Shaking edges, rolling ground waves and trembling cracks show its area and duration. Faultline Rush remains a separate mastery alternative; its description now explains the quake trade-off.

## Crossroads Cat
Shadowstep hides the Cat from opposing players in Arena and Battlegrounds, including the sprite, shadow, nameplate, health bar, minimap marker, damage feedback, status markers and attached guard/attack effects. Owner and allies retain the existing faint silhouette. Broadcast spectators can still see the match. Expiry or attacking reveals the Cat. Invisibility does not grant immunity to area attacks. Existing stealth timers and their network replication are reused.

## Twisterspell
- Pocket Twister: tap/release starts at six base damage per 0.5-second contact tick. Full charge at 1.6 seconds reaches 14.4 damage per tick. Radius grows from 36 to approximately 61. Four funnels maximum, lasting 4.2 seconds.
- Fully charged funnels pull foes toward the centre much more strongly, at up to 100 units per second within radius + 65. Pulls respect walls and walkable ground.
- **Storm Circuit** replaces the duration passive. At level five, three or more owned funnels within 260 reach link lightning every 1.25 seconds. Crossing enemies take eight base damage and a 0.35-second stun. Fully charged funnels can independently zap a nearby enemy for ten damage every 1.5 seconds. A foe can be shocked at most once per second per caster, preventing overlapping circuits from chaining continuous stuns. Allies are unaffected; walls block shocks.
- Wide Forecast mastery uses two wider funnels: five to twelve damage per tick, radius 48 to approximately 82. It retains fully charged direct zaps but trades away the three-funnel circuit.
- Lightning is visibly drawn, short-lived, bounded and carried in combat snapshots. The passive no longer extends tornado duration.

## 80. Hearth Herald — Support / Melee
An armadillo firekeeper from Ember Quarry, with original lantern, cloak and segmented-shell artwork in idle, two walking and attack poses.
- **Lantern Tap:** short forward melee sweep; 18 damage, 95 reach, 0.65-second cooldown.
- **Kindle Arms:** enchant self and friendly heroes within 220 reach for five seconds. +8% attack damage; direct hits apply burn for two base damage per second for three seconds. At most one burn application per target per attacker per second. Twelve-second cooldown; identical enchantments do not stack.
- **Shared Hearth:** self and nearby allies within 170 reach gain 10% damage reduction. Walls block the aura, multiple copies do not stack and the existing DR indicator shows its protection. Combat-only; inactive in town.
- **Homefire Beacon:** place a banner at a safe aimed spot within 280 reach. For six seconds, allies within 180 recover four HP per second. It catches up to six hostile projectiles entering its circle, preserving friendly shots. One banner per caster; 24-second cooldown.
- First mastery, **Restorative Chorus:** replace added burn with three HP life-on-hit, retaining the damage bonus. One trigger per target per attacker per second. Damage-over-time cannot trigger either enchantment.
- Final mastery, **Open Hearth:** banner heals seven HP per second but cannot catch projectiles.
- Master title: **Keeper of the First Flame**. Standard clear/damage requirements and critical milestones. All heroes remain available from the start.

## Validation and performance
Godot 4.5.1 checks passed for quake timing/exact total and early escape, ally protection, stealth visibility across teams and free-for-all, charged tornado damage/radius/pull, three-funnel lightning and independent full-charge zap, passive gating and shock limits, support buff allegiance, DR aura, burn/DoT exclusion, life-on-hit mastery, banner healing and catch limits, snapshot round-trip, guest authority, training ally buffs and town cleanup. Existing v107–v111 regressions passed. Rendered and inspected quake, lightning, Hearth Herald's Character Hall/practice view and Cat visibility before/after stealth. ZIP CRC and complete extraction checked. Live multi-computer play and compiled Web/Windows exports were not tested here.

Effect arrays, lightning visuals and on-hit cooldown tables are bounded or expire promptly. Existing input, room transport, status effects, profile progress and healing accounting are retained. Source/vector artwork and the updated student catalogues are included.

## Publish
1. Extract this editable ZIP into a fresh folder. Open FX_Crossroads/project.godot and let Godot import assets.
2. Re-export the Web preset and replace the browser build on itch.io with its exported ZIP. This file is the editable project, not a compiled Web export.
3. For Windows, run BUILD_WINDOWS.cmd and upload exports/FX_Crossroads_Windows_v112.zip separately. Keep multiplayer users on the same version.
4. **Render requires no file or settings changes for this update.**
