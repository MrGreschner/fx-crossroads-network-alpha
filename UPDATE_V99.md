# FX Crossroads v99 — character polish

Includes all v98 features; 74 heroes remain available.

- Crossroads Cat now has a clearer head, attached upright ears, whiskers, paws and scarf. Idle, walking, primary attack and spin art share its original 28×32 footprint and restrained palette.
- Cobbleclaw's Shell Receipt guard and projectile catch window both last **3.5 seconds**. Its cooldown, four-shot cap and bank expiry are unchanged.
- Wick-o'-Wisp's gameplay aura and bonuses are restricted to active gameplay; town and lobby no longer draw the aura. Scary Face projects two triangular beams from its carved eyes, with a faint outline of the actual forward fright fan.

## Cosmetic effects

| Hero | Added detail |
| --- | --- |
| Wick-o'-Wisp | Small orbiting candle fireflies and amber moving wisps |
| Molten Pilgrim | Fading red snail smudges |
| Clockwork Apiarist | 1–3 tiny orbiting bees, including while idle |
| Morrow Shepherd | Subtle dark mist behind the character and trailing clouds |
| Ripplejaw | Landing puddles and ripples, once per completed flop |
| Velvetwing | Falling purple wing sparks, also while hovering idle |
| Vesper | Silver-blue star and crescent traces |
| Sunpetal | Drifting golden petals |
| Iris Chalkbinder | Small chalk traces |
| Tumblebrew | Rising steam at rest and a moving steam trail |

All cosmetics are local rendering. No extra network packets or particle nodes. Trails share the existing 96-entry budget, expire in 1.6 seconds, and skip off-screen drawing. Idle companions are calculated from a small tracked-actor cache; stale/dead/disabled actors are removed. None of these effects changes combat or movement speed.

The editable cat-art generator is tools/build_v99_cat.py. The ability catalogue documents the reusable cosmetic system. See DEPLOY_V99.md and RELEASE_CHECKS_V99.md.
