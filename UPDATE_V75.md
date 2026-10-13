# FX Crossroads v75

## Mastery page
- A compact hero selector and portrait.
- First and final ability techniques are adjacent, with independent equip/original buttons.
- Descriptions open using **What changes?**; requirements and progress stay on their cards.
- Crit milestones appear below the technique cards, followed by three compact point-investment rows.
- Existing unlock thresholds, saved builds and balanced tuning limits are preserved.

## Ripplejaw
A river fish with a tideglass harness and a visual flop gait. Ground collisions and movement speed remain consistent.
- Water Gun: three short water pulses, 21 total damage, 300 reach, 0.8s cooldown. No piercing.
- Splish Splash: 26 damage in a 110-radius splash, then three 55-radius puddles for 4s; 40% slow while inside. 6s cooldown.
- Below the Surface: aimed foe within 480; a shadow follows at 75 speed for 1.6s, locks for 0.4s, then bites. 72 damage, 100 radius, 1.25s stun and inward pull. Bosses resist the pull. 15s cooldown.
- Slippery Scales: from passive level 5, reflect every third incoming moving projectile. Return damage is 80%, capped at 30. Beams and explosions are not reflected.
- First mastery: larger, longer puddles in exchange for lower splash damage.
- Final mastery: a fixed pulling whirlpool instead of the tracking bite; six 10-damage ticks, no stun.

## Hearthwarden
A human frontline guardian in copper armour with a smith’s hammer.
- Forge Rhythm: 22/22/33 close-combat combo; the third swing is wider and pushes. 0.7s cooldown. Pausing 1.8s resets the combo.
- Rally Standard: 5s banner, 130 radius, 18% damage reduction for its owner and allied players. 9s cooldown.
- Hold the Line: advancing 220-wide shield, 50 damage once per foe, brief stun/slow/push; catches six hostile moving projectiles. 17s cooldown. Walls stop travel, and beams/lobbed explosions bypass protection.
- Steadfast Forge: third swing grants a visible 15% protective ward for 2s.
- First mastery: a smaller, weaker banner that travels with its owner.
- Final mastery: three charged falling anvils replace the shielding march.

Both heroes are free, include four matching sprite poses, titles, unlock requirements, critical milestones and both independent mastery alternatives. They use the shared combat dispatch in realms, quests, Descent, Defence and PvP.

## Chimehouse
The original challenge plus five new ones: Twin Bells, Quick Duet, Threefold Echo, Silver Cascade and Midnight Carillon. Tap twice or three times in sequence as the light crosses the gold windows. Later levels run faster with narrower windows. Five patterns per level; 80% clear notes enables Next Challenge. All levels can be selected directly for practice. Early taps consume a note; missed notes advance automatically. Bell pitches rise through each pattern.

## Validation
Godot headless combat tests cover water pulses/non-piercing, bounded puddles, tracking/pull/stun, exactly six whirlpool ticks, reflection, combo/armour, banner protection, shield limits and snapshot serialization. UI tests cover adjacent cards, independent techniques, every rhythm level, early/missed taps and menu cleanup. Existing mastery, town and North Gate regressions are checked. Native rendered previews are inspected for layout and effects.

Actual iPhone Safari input and live cross-device multiplayer still require playtesting. This source archive contains local Windows build tools, not a precompiled Windows EXE. Re-export Web for itch.io, and use matching v75 builds for multiplayer. No Render service change is needed.
