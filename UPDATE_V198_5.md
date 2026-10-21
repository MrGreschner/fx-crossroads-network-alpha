# Crossroads: Realms Beyond — v198.5

Build `V198.5-river-discoveries` · protocol 11 · Godot 4.5.1
Based on v198.4, including its hero updates and all earlier accepted fixes.

## Fishing notifications

Replaced the old Panel/RichTextLabel record popup with a small draw-only HUD notice at the top of the screen. It creates no Control, window, focus target or input blocker. Only one message is visible; a newer message replaces the old one. It fades after three seconds, including while paused, and resizes with the viewport.

First catches say **NEW SPECIES**. Larger specimens say **NEW PERSONAL BEST**, followed by species and weight. Catching either still updates the journal, fishing XP and community records as before.

## Compact species trophy leaderboard

Each species trophy entry puts a larger fish thumbnail, species/weight, holder, rarity and compact weight bar together. The bar keeps the species-average and trophy-threshold markers. Rows wrap on narrow screens. This replaces the large dial underneath the text that produced the empty space shown in the supplied screenshots. Other weight dials remain available in fish details.

## Ten new river species

| Rarity | Species |
| --- | --- |
| Common | Copperfin Shiner, Mossback Gudgeon, Ribbon Bleak, Russet River Chub |
| Rare | Opal Riffle Trout, Saffron Sail Grayling |
| Legendary | Crownwater Sturgeon, Emberjaw River Pike |
| Mythic | Moonthread Arowana, Starveil River Ray |

All ten are available in East Bridge River. The common species also occur in Wayfarer Brook and Deep River Bend; the rare, legendary and mythic species also occur in Deep River Bend and Moonwater Cascade. Common species accept rod/net; higher rarities use the rod. No new bait or time restriction is required. Existing relative rarity weights continue to apply; rare catches are not guaranteed.

Mythic species use the existing **Mystical** catalogue category, preserving compatibility with saved profiles and community ranking rules. The catalogue now contains 103 species.

## Distinct aquatic artwork

Added ten separate editable SVG illustrations. Differentiated 29 existing shrimp, crayfish and crab species with individual palettes, markings and pose angles. Reedglass Shrimp and Current Shrimp now visibly differ. Updated the embedded SVG sources used by the game, as well as the measured display geometry, so the new art appears in journals, catches, displays and boards. Original species IDs and existing catch statistics remain.

## Validation

- New fishing/UI suite: **246 checks passed**, source and packaged web PCK. Covers all 103 artwork loads, unique rendered images, new species availability/save validation, exact rarity counts, first/larger catch notifications, bounded notice layout, pause expiry and compact desktop/mobile trophy rows.
- New server catalogue validation: **30 checks passed**, including accepted new species trophy records and rejection of impossible weights.
- Previous six-shooter/fishing regression: **88 checks passed**, adapted to the draw-only notification.
- Previous v198.4 hero gameplay: **44 checks passed**.
- Community API regressions: **23 + 19 checks passed** against a local PostgreSQL-compatible test database.
- Dashboard repair regression: **74 checks passed**.
- Web PCK resource checksums round-tripped; deployment ZIP CRCs and required files checked.

Real-device visual/play testing remains, particularly on school Chromebooks and phones. No fresh eight-client live networking test or live deployment was performed for this update.

## Deploy manually: server first, itch.io second

1. Apply **Crossroads_v198_5_Server_Update.zip** at the root of the existing Render source project. Keep the current service, database connection, environment variables, passwords, signing secrets and keys. Use the existing Dockerfile.network setup; deploy and confirm `/health` reports `V198.5-river-discoveries`.
2. Upload **Crossroads_v198_5_Web.zip** to the existing itch.io HTML game. Keep the complete ZIP, including `web/browser`. Refresh the browser/game after deployment.
3. Keep **Crossroads_v198_5_Editable.zip** as the full editable Godot project.

The matching server is needed to validate and publish records for the ten new species. No database reset or schema change is included. Existing accounts, saves and previous trophies are preserved. The earlier dashboard repair is included; the state of the live dashboard still needs checking after deployment.
