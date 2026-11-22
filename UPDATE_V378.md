# V378 — Riverfront town and separate Wayfarer watershed

Complete release based on V377. Refines only the illustrated regional chart and its descriptions; the actual maps, world geometry and travel destinations are unchanged.

- Crossroads now sits directly along its river, with town buildings on both banks and the east bridge inside the riverfront settlement. The main town remains west of the river; the Gatherers’ Lodge and riverside buildings appear on the east bank. The marina adjoins the river south of town.
- Woodland begins immediately beyond the east-bank buildings, along the trail into the forest. The north riverside branch still leads to Oldwater Bay; the southern trail still reaches Tidecross.
- Wayfarer Wilds is farther east, beyond a wooded hill ridge. Its separate river begins at headwaters on the eastern side of that ridge, passes the Wilds entrance and drains to a separate sea mouth. It never joins Oldwater Lake or its river. A second timber bridge shows the trail crossing Wayfarer’s river.
- Tidecross remains west of the original river delta. Oldwater Bay stays on the northeast shore of the lake. Hills use stepped, layered matte contours; the Wilds landmark reuses the existing Wayfarer lodge artwork. All six numbered destinations retain working local-map links.

## Validation

Native summer and winter regional charts reviewed for riverfront buildings, forest placement, separating hills, independent headwaters/outlets, route labels and sidebar fit. Godot checks cover buildings on both banks, adjacent town marker, farther-east Wilds marker, disjoint river segments, ridge between watersheds, bridge spans and clickable moved regional pins. The V377 local-map, winter fishing-hole, directory, mouse/touch and menu-layer tests also pass. Existing resource-cleanup warnings remain at process shutdown. No live browser/mobile/Render deployment test was performed.

Full ZIP CRC, duplicate-path and final-source-byte checks; all web part offsets/sizes/hashes, assembled PCK hash and every PCK entry digest; actual packaged modules and image dependencies checked. Complete Web, Server_Project and Editable builds require no previous version. Individual Web/Server files remain below 100 MB and web data chunks at most 32 MiB. Source packages keep the original full project/artwork and Dockerfile.network workflow. Extract package contents before copying into your GitHub folder; do not commit the download ZIPs themselves.

This is an atlas presentation update. No server mechanics, ownership, protocol or database schema changes. EPOCH4 and protocol11 remain; V376/V377 server authority is compatible with the V378 web atlas. V376 locked-hero training restrictions, V375 combat fixes and all prior game content remain.
