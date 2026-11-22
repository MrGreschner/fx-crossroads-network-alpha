# V379 — Inland Wayfarer placement, ridge streams and richer map frontiers

Complete release based on V378. Refines the illustrated region map; actual world geometry and local travel/fishing anchors are unchanged.

- Wayfarer Wilds is now inland on the west/left side of its own river, with a wooded gap between the landmark and water. The approach road ends at the Wilds without crossing that river. Its landmark sprite, numbered pin, hit target and directions move together.
- A separate snowy mountain range rises farther east, beyond the river and a belt of forest. These high peaks retain their snow caps in both summer and winter charts. The middle wooded ridge between Crossroads and Wayfarer remains.
- Three small streams originate on the middle ridge: one drains west into Oldwater Lake, while two drain east into Wayfarer’s river. Tributaries on opposite slopes do not join across the watershed. Their stable atlas IDs are ridge_lake_run, ridge_wilds_upper and ridge_wilds_lower. They are map features reserved for future fishing-area design; no active fishing holes or pools have been added in this release.
- Reworked the far west with staggered hills of different sizes, mixed woodland, irregular clearings and soft frontier washes. A fixed local random seed gives the western woodland natural spacing without changing the game’s random state. Terrain and forest reach the margins; the snowy eastern range continues beyond the chart edge. Small labels distinguish the middle ridge, snowy heights and uncharted reaches.
- Town remains directly along its original river with east-bank buildings and nearby forest. Oldwater Bay, the harbour and its delta retain their V378 geography. All regional destinations still open their appropriate local maps.

## Validation

Godot 4.7.2 atlas tests pass for the inland west-bank setback, approach ending before the river, snowy peaks east of the river with a separating gap, three ridge-source streams and their correct outlet catchments, and selection of all moved regional pins. Local-map anchor/bounds/projection, directory, mouse/touch scaling, winter ice-hole rotation, ferry closures, read-only browsing and boat-menu map callbacks also pass. Native summer and winter renders reviewed. Existing resource-cleanup warnings remain at engine shutdown; no live browser/mobile or Render deployment test was performed.

Full packages are checked for ZIP CRCs, duplicate paths and final changed bytes. Web part offsets, size limits, per-part and assembled hashes and every PCK entry digest are checked. Actual packaged modules and artwork dependencies load successfully. Complete Web, Server_Project and Editable packages require no older version. All individual Web/Server files remain below 100 MB; web game-data chunks are at most 32 MiB. Source packages keep the full original art, scripts, project.godot and Dockerfile.network deployment workflow. Extract the packages before copying their contents into GitHub; the ZIP downloads themselves are not files to commit.

This is an atlas presentation update: no combat, ownership, server mechanics, protocol or database schema change. Ownership EPOCH4 and protocol11 remain. V376–V378 compatible server authority can use Web V379. Existing unlock/training restrictions and combat fixes are preserved.
