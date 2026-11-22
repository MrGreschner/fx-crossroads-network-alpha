# V381 — Consistent regional settlement symbols

Complete release based on V380. All regional settlements now share one compact pictogram family, with a clear hierarchy: Crossroads is the main town and largest mark; Tidecross Harbour and Wayfarer Wilds are equal-sized smaller settlements; Oldwater Bay is a smaller lakeside outpost.

- Shared atlas_symbols381 renderer uses the same matte stone, muted slate roofs, warm coloured contours and stepped pixel shapes for every location. Crossroads has a compact civic-gate/tower symbol (36×28 design bounds); Harbour and Wayfarer share the same two-roof settlement structure (26×22 each), with small harbour/woodland cues; the Bay uses a hut-and-landing mark (18×16).
- Replaced all inconsistent regional building sprites, the oversized harbour neighbourhood, separate harbour piers/ships and the large Outback Cabin depiction. Local town, harbour and bay directories retain their real buildings, docks and entrance positions. Settlement symbols represent places rather than literal street layouts or physical sizes.
- Regional destination descriptions identify the main town, harbour settlement, woodland settlement and lakeside outpost. Schematic ferry lines meet their regional destination markers. Location pins and labels remain in their approved positions.
- Existing lakes, river systems, delta, Wayfarer’s inland west-bank setting, middle ridge and tributaries, eastern snowy heights, forest and uncharted western terrain are preserved. No new fishing pools or gameplay areas were added.

## Validation and full packages

Native summer/winter regional renders reviewed. An isolated transparent render measures actual visible symbol bounds: Crossroads is larger in width and height than either secondary settlement; Harbour and Wayfarer have equal visible bounds; Bay is smaller. Godot integration checks cover every regional mouse/touch selection, correct local-map link and actual local pin projection, symbol bounds, closing back to gameplay and unchanged player state. Existing engine resource-cleanup warnings remain at shutdown. No live browser/mobile playtest or Render deployment was performed.

Complete standalone Web, Server_Project and Editable packages contain all prior content and require no older release. ZIP CRCs, duplicate paths, changed bytes and every unchanged source file are checked against V380. Every web chunk’s offset, size and digest, the assembled game-data digest and every PCK entry digest are checked. Actual packaged atlas modules and dependencies load in Godot 4.7.2. All individual Web/Server files remain below 100 MB; web chunks are at most 32 MiB. Source packages keep the full artwork/scripts/project.godot and Dockerfile.network deployment format. Extract contents before copying into GitHub; the download ZIPs themselves are not files to commit.

Atlas presentation only. Ownership EPOCH4, protocol11, database schema, unlock/training guards and combat mechanics are unchanged. Compatible V376–V380 server authority can use Web V381.
