# v144 — Mine metals, direct navigation and targeted optimization

## Adventures
The top Adventures button now offers Combat & exploration and Build, trade & create tabs. Idle Mining, Crossroads Market, public Studio, Training Yard and First Steps all launch directly. Academy appears only for an education-unlocked account. Arena text correctly mentions solo AI practice. The modal supports touch swipe scrolling.

## Mine to furnace to Market
| Metal | First shaft | Depth | Recipe for one bar |
|---|---:|---:|---|
| Copper | 2 | 60m | 6 copper ore + 1 coal |
| Iron | 4 | 120m | 8 iron ore + 2 coal |
| Cobalt | 7 | 210m | 10 cobalt ore + 3 coal |
| Mithril | 11 | 330m | 12 mithril ore + 4 coal |
| Emberite | 15 | 450m | 14 emberite ore + 5 coal |
| Starsteel | 18 | 540m | 16 starsteel ore + 6 coal |

Metal production follows the mine's airflow, digging and lift throughput. Every unlocked seam keeps producing; its surface case holds 1,200 ore. Collect Depot transfers this material and coal into the spendable wallets. Full storage pauses extraction safely; the existing 24-hour offline limit remains.

Use **Smelter & metals** to forge 1, 5 or 10 bars. One furnace processes a bar batch OR an ordinary ore-to-gold order. Higher Smelter levels shorten batches. Its progress gauge counts up, and completion works while away. Cancelling an unfinished bar order refunds only its consumed inputs.

Bars have two uses:
- Prepare them as one of six new Market products. Pricing, customer choice, advertising and reports work as before. Metal stock consumes actual forged bars and processing cash; it does not spend generic ore again. A 55%-of-reference material opportunity cost is included in operating profit, separate from processing cash.
- Use them for deeper shafts and building upgrades from shaft 5. The required metal has already unlocked at the preceding depth. Costs are shown alongside gold, ore and gems. Early building costs remain ordinary resources, and an old deep mine can build its first furnace without needing bars.

While a build runs, one **reinforcement delivery** consumes an extra bar batch and reduces remaining build time by 35%. It can be used once per build. Cancelling construction refunds both the original and reinforcement bars. Completed buildings consume those materials.

This economy stays separate from hero gold, damage and equipment. Existing mine and six-product Market saves migrate without losing their progress. Furnace orders, bars and metals travel in the downloaded player profile. Game Dev remains temporary; Playtest actions remain blocked.

## Targeted performance and reliability fixes
- Cold terrain tiles use a spatial index instead of scanning every road polygon. Patch order and resulting tiles are preserved, including overlaps and negative western coordinates. Region changes rebuild the index.
- A full tile cache evicts a small oldest batch rather than throwing away all cached tiles at once.
- Legacy profile saves reuse their serialized JSON instead of encoding the same dictionary twice.
- Market campaign typing saves after a short pause, or immediately when closing, rather than rewriting a profile on every keystroke.
- Empty list arrow-key navigation is guarded.
- Market uses consistent panel scaling on narrow screens; report exports are on Reports, leaving visible Mine and Back to town buttons.

The cold-tile benchmark covered 3,195 town tiles and 108 path patches. Full scan: 345,060 polygon checks. Indexed scan: 3,264 (99.05% fewer), identical output. A local sample took about 3–4ms versus 66–78ms including index construction. This measures terrain work only, not whole-game FPS or browser graphics-driver reliability.

Official hero definitions and existing artwork remain unchanged.
