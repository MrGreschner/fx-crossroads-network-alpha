# Crossroads: Realms Beyond — v198.31 • Darkwater Swells

Build `V198.31-darkwater-swells`. Full release based on v198.30, preserving the marina, town routines and all earlier gameplay work.

## Shared time and much darker nights

Lake and ocean now use the town's real 24-hour Edmonton calendar and weather. Removed the accelerated one-hour-per-30-seconds voyage clock and the five-minute weather rotation. Starting, anchoring, landing and resuming a saved voyage cannot fast-forward the hour. Existing cargo, cages and elapsed voyage timers remain compatible; cage readiness still uses active voyage seconds.

Night Island stays at one location throughout a real night, including across midnight, and changes on the following night. Its emergence/disappearance follows the town clock (20:00–06:00). Dawn still returns island visitors safely to their boats. Previous checkpoint fields remain readable; no profile migration is required.

Outside the boat's smaller lantern radius, nighttime opacity is now 99.8%, approaching black. The lantern stays aboard when you explore an island. The night chart shows small island markers rather than full silhouettes, so it does not reveal island dimensions in darkness. Dawn/dusk retain gradual transitions. The mask remains cached and covers the whole viewport.

## Islands with character

Every lake and ocean island has an asymmetric coastline with coves, headlands and a distinctive outline. The same contour is used by art, on-foot terrain, boat collision, island approach and landing. Sandy shores, greenery, trails and beach details follow that contour.

Birch Landing has pale striped birch trunks; Oldwater Isle has weathered stonework; Reedwatch has thick reeds; Shore Refuge has broken wreck ribs; Kelp Rest has stranded kelp and old mooring posts; Night Island retains its crater pool with marked stone fragments. Existing enemy camps and fishing remain available.

## Medium and large ocean swells

Visible travelling crests carry rolling blue water and broken foam. Offshore waves arrive from varied directions; additional surf pushes toward nearby islands or the mainland. Storms increase offshore frequency. A warning precedes each wave's force; the voyage bar identifies swells and surf.

Waves push the actual boat in addition to currents. Medium and large fronts have different widths, speeds and force. Steering sideways can escape a crest; anchoring reduces drift. Existing collision rules prevent crossing land and apply hull damage if a wave carries an unanchored boat into a hazard. The harbour remains sheltered. At most eight wave fronts exist at once, with viewport culling for drawing. Lake currents remain; large ocean swells are exclusive to the coast.

## Server package and Defender report

The screenshot identifies `Trojan:Win32/MalUri.A!cl` and lists both v193.1 and v198.30 archives, plus Chrome cache files. The alert does not identify an individual source file, so it does not establish which archive member caused the detection.

The new Render package is rebuilt from the project source and excludes generated `.uid` files, PDFs, test files and the separate room-service source (all retained in the editable project). It contains no bundled Windows executables or prebuilt Godot engine. The Docker build continues to obtain the official, SHA-256-verified Godot release. npm dependency lifecycle scripts are now disabled (`npm ci --omit=dev --ignore-scripts`). Existing account, database and key configuration are retained.

A structural archive audit and hash inventory are included. These are **not an antivirus scan**. Windows Defender is unavailable in this workspace; the cause and a clean Defender verdict remain unverified. Do not bypass or allow a flagged download. If the replacement is flagged, retain the detection details and use Microsoft's file-analysis process: https://www.microsoft.com/en-us/wdsi/filesubmission . Protection History guidance: https://support.microsoft.com/en-us/windows/security/windows-security/protection-history-in-the-windows-security-app . No project files were submitted to an external scanner.

## Validation and manual deployment

**31,229 automated checks passed against the packaged runtime:** 3,919 voyage checks, 6,018 Citadel/fishing/voyage regressions, 79 Quarantine/Game Dev/night checks and 21,213 marina street/routine checks. These cover clock rate, resume, overnight island identity, darkness coverage, landings from every shoreline direction, boarding, real wave-driven movement, anchored drift, bounded wave counts and collision damage. Citadel/fishing/voyage, Quarantine/Game Dev/night and marina-route regressions are included. See validation/v198_31 for final results. Native exits retain existing resource-cleanup warnings.

Clean server import/boot, source/server/web agreement, ZIP integrity and baseline preservation are checked. Manual browser/device and student playtesting remain necessary, especially for swell strength and nighttime navigation.

No production changes or database migration. After the server archive has a clean local security scan, deploy **server first to Render**, then **web to itch.io**. Preserve the existing database URL, keys, environment variables and persistent storage. The editable ZIP contains the full project, including the separate room-service source and prior notes.
