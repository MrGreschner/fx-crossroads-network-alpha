> v135 change: choose 5 minutes–24 hours per business day. Opening starts a saved countdown, not instant settlement. Decisions lock while trading. One day completes while away; the next requires a new explicit opening.

# v134 — Crossroads Market & town landscape

Crossroads Market connects Deepwell Mine to a separate, educational business simulation. It is southwest of the pond, east of the mine approaches. Visit it with E/Interact or from Profile. The mine has a Market shortcut; the market can collect the mine depot.

## Business play

- Six product lines unlock at shafts 1, 2, 3, 6, 10 and 14: sorted ore, forged tool blanks, polished crystals, Silverfall pendants, crystal lanterns and clockwork keepsakes.
- Mine ore/gems are consumed when products are prepared. Processing costs use **market cash**, not hero gold. Start with 160 market cash.
- Choose price, customer segment, campaign channel and positioning. Write a shop name, campaign headline, forecast and reflection. Open one business day explicitly; there is no real-time market timer or unattended sales.
- Three customer groups: builders, collectors and guilds. Three campaign channels and messages. Pricing, product fit, channel fit, quality, service, reputation and a five-day event cycle change demand.
- Stock, unmet demand, reach, visits, conversion, satisfaction, revenue, cost of goods, advertising, overhead, operating profit and ROAS appear in reports. A chart shows recent daily profit/loss.
- Upgrade finishing quality, service or premises through five levels each. Research customers. An 80-cash working-capital loan requires 100 repayment before another loan; borrowing never counts as sales.
- Optionally reinvest market cash as Mine Gold, 1:1. Mine and market never modify hero gold, stats or mastery.
- Copy/download a JSON business report. Last 100 business days include decisions and written forecast/reflection; lifetime totals remain separate.

## Teaching

The Business Classroom explains the four Ps, segments, opportunity cost, inventory, cash flow and controlled experiments. Headline text is preserved as assessment evidence; **the game does not automatically judge student writing**. This is a transparent teaching model, not a forecast of real markets. Material opportunity values are 0.45 cash per ore and 8 cash per gem. These are accounting conventions, not spendable conversions.

Profile and player card distinguish ore/gem achievement levels and depth from market sales and operating profit, so resource success and marketing success can be assessed separately. Elder Ram explains the mine, market and all four Studio labs.

## Town

The north fence extends west to the mountain boundary with matching solid collision, closing the pond-side shortcut to the battlefield. The pond is larger with a curved bank, stones, reeds, fish and an independent waterside path. Its bench and shore avoid the Character Hall. Western mine, market and Studio branches share a dirt/cobble finish. A scaffolded future-development building sits between Studio and Squirrel Post.

## Saving/testing

Mine remains `progress.mine`; market is `progress.commerce` in `profile.json` inside the player ZIP. Older profiles without commerce get the starter business. Malformed financial/history data is rejected before profile replacement. Game Dev edits remain temporary and cannot overwrite normal accounts. Playtest market actions are disabled.

No room-service or Render changes are required for v134 relative to v133. Re-export Web and optional Windows packages from this editable project. This ZIP is source, not an already exported game.
