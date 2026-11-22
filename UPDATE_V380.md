# V380 — Compact town symbol on the region map

Complete release based on V379. Corrects the regional chart's visual scale: Crossroads is now one small civic symbol and numbered location marker beside the river. Removed the spread of individual buildings across both banks and the large town-shaped clearing. The compact marker leaves more surrounding countryside visible, so the lake and coast no longer read as neighbouring town blocks. The town label sits to the west, clear of the river. The south trail connects directly to the marker, and ferry lines begin beside it rather than at a separate detailed marina symbol.

The region description explains Crossroads' riverside position and its north, south and east routes. Detailed streets, buildings and their actual positions remain on the separate local town map. The approved river/lake/coast geography, Wayfarer's inland west-bank position, snowy eastern range, middle ridge, three future-fishing tributaries, forest and western frontier remain unchanged. The chart remains schematic and explicitly not to scale; world maps and travel distances have not moved.

## Validation and delivery

Native summer/winter regional renders and the local town map reviewed. Map interaction checks cover selecting the compact town marker by mouse and touch, opening the correct local directory, retained actual local entrance pins and coordinates, and all regional destination links. Comparison against V379 verifies that the approved non-town geography and all unmodified source files remain identical.

Complete standalone Web, Server_Project and Editable packages include all previous game content and require no older version. ZIP CRCs, duplicate paths, changed bytes, every web data part's offset/size/hash, the assembled game-data hash and every PCK entry digest are checked. The packaged atlas and its reused image dependencies are loaded in Godot 4.7.2. Every individual Web/Server file remains under 100 MB; web chunks are at most 32 MiB. Extract the ZIPs before copying their contents to GitHub. Source packages keep the full art/scripts/project.godot and Dockerfile.network deployment format.

Atlas presentation only: no gameplay, ownership, protocol or database change. EPOCH4/protocol11 and locked-hero training restrictions remain. Compatible V376–V379 server authority can use the V380 web atlas. Existing engine resource-cleanup warnings at shutdown persist. No live browser/mobile playtest or Render deployment was performed.
