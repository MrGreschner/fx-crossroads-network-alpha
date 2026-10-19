# v186 — Living gardens and community harvests

## Files to upload

1. Update the existing GitHub/Render service with the contents of **Crossroads_v186_Server.zip**. Deploy it before the web game. Client and server reports identify as **V186-preview**, protocol 11.
2. Upload **Crossroads_v186_Web.zip** as the HTML game on the current itch.io page. `index.html` is at the ZIP root. Mark the ZIP as playable in the browser.
3. **Crossroads_v186_Editable.zip** contains the Godot project, generation tools, QA scripts and validation results.

Keep the existing Render database, environment variables and signing secret. New community tables are created additively; no database reset or replacement is needed. Existing portable profiles, garden beds, seed stocks and learned perk IDs remain compatible. Download a profile backup before updating the live game.

These files have been checked locally; they have not been deployed to your live Render or itch.io accounts. After deployment, confirm that a normal profile can open Gardening, zoom the tree, plant a fair crop and retrieve Community Records. A real mobile and school-device check remains useful.

## A connected Gardening tree

All 64 perks share a single upright tree with the four trunk perks, Cultivation, Botany and Stewardship, and all nine specializations. Open **Gardening → Mastery tree**. The overview fits the entire graph. Use the mouse wheel, +/− buttons or pinch to zoom; drag to pan. Click a symbol for its effect and requirements in the separate details panel. Learn there; fork choices and the 33-point limit still apply.

Every perk has an effect symbol and an individual rune frame. Labels appear when zoomed in and sit on opaque backing so lines do not cross the words. The Glimmer reset requires confirmation and preserves XP, seeds and plants. Active giant crops retain the mastery bonus calculated at planting.

## Seeds and botanical art

There are now **80 crops**: the previous 56, eight new Rare seeds, four new Legendary seeds and twelve monthly fair crops. All have editable seed-packet, sprout, mature and harvested-item illustrations. Fruit, roots, mushrooms, herbs and flowers use different botanical silhouettes and structures. The inventory loads twelve crop cards per page, with compact collection/family filters.

New Rare seeds: Glass Pomegranate, Velvet Fig, Cobalt Thistle, Ember Artichoke, Spiral Romanesco, Inkmorel, Ribbon Salsify and Crown Protea. Legendary: Dragon Cacao, Cathedral Agave, Phoenix Strelitzia and Cosmic Daikon.

Overcharged roaming Conclaves are the main high-rarity source. Completing an entire pack uses the existing successful-settlement reward hook. Some Rare seeds can also be bonus finds on the first successful completion of rotating missions or weekly goals. These are chances, not guaranteed rewards. Existing fishing, town, realm and gathering sources remain. Required gardening levels still apply; seed finds are limited to twenty levels above the player's current gardening level. Legendary seeds have lower selection weight than other eligible elite seeds.

## Giant growers fair

The dedicated plot is separate from ordinary garden beds and needs no bed unlock. One giant crop can grow at a time. The current month's seed is provided on planting. The same crop can be grown again after harvesting, while its month remains active.

Each giant crop takes **seven real days**, including time spent away. Normal growth-time perks cannot shorten that timer. Free care is available once per Edmonton calendar day, up to seven visits. Each visit adds 6% size. Optional compost consumes one Common or Uncommon harvested item and adds 8% for that visit instead; rare produce is preserved. Missing days never ruins a crop.

Yield, ingredient and seed-recovery mastery contribute a planting bonus, capped at 20%. Natural size variation is ±15%; care and mastery then multiply that starting weight. Harvest awards one usable produce, 24,000 Gardening XP and a saved weight record. Harvesting twice cannot duplicate the reward. Care, remaining time and harvest readiness have visible feedback.

| Month | Crop |
| --- | --- |
| January | Winter Cabbage |
| February | Heart Beet |
| March | Emerald Broccoli |
| April | Rainbow Chard |
| May | Sunburst Squash |
| June | Ruby Strawberry |
| July | Summer Watermelon |
| August | Golden Sunflower |
| September | Autumn Gourd |
| October | Harvest Pumpkin |
| November | Hearth Parsnip |
| December | Winter Pineapple |

A crop belongs to its **planting month**, even when harvested next month. Personal all-time records and the latest 24 planting-month records travel with the portable profile. Community Records shows the current month and all-time crop records. The server ignores very old monthly submissions without blocking the rest of the profile's upload.

## Community and town

Community Records now includes rarest fish this week and all time, with fish artwork. Rarest means species rarity first, then the species' lower base catch weight in the catalogue; size is a tie-breaker within the same species. This is separate from largest fish. Weekly rarity starts tracking catches in v186; existing species-journal personal bests can seed all-time rarity. Old clients can contribute their largest weekly fish as a fallback. These are anonymous, client-reported records, not verified competitive leaderboards.

The exterior board is now wood, roof shingles and pinned parchment. The portal retains a cool blue pool of night lighting without the yellow emitter dot. Training Yard window overlays follow the corrected artwork aspect ratio. The nearby planters form a column clear of the main path. Two guards patrol the Ram's Descent approach beside additional animated torches.

The existing activity system also records giant-crop harvest weight, XP, species and seven-day duration for later analysis. Solo play and garden timers still run locally.

## Validation

45 native Godot checks passed, including profile compatibility, the full tree, new catalogue, seven-day timers, daily care, compost consumption, duplicate harvest protection and all eight new guard-route points.

Database checks passed using PostgreSQL-compatible PGlite: 19 new community checks, 23 existing community checks and 24 existing activity checks. They cover repeated/stale uploads, rare fish ordering, seasonal weights, month/week rollover, validation, anonymity and existing telemetry.

Chromium WebGL checks cover the full tree, actual mouse-wheel zoom, drag panning, symbol selection, learning a perk, fair controls, seed inventory, community cards and the changed town locations. Art validation parses all 320 growth illustrations and 64 perk badges, and confirms distinct harvest SVGs for all 80 crops. Screenshots use QA fixtures and are not live community data.
