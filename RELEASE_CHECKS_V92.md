# v92 validation

Checked locally with Godot 4.5.1 and the Node room service. This is an editable source release; Web/Windows export templates were not available here, and no deployment was performed.

## Automated checks

- `tests/v92_battlegrounds.gd`: passed. Six/eight-player synthetic teams, three/four paths, individual barracks, automatic army marching/combat, all 72 hero kits casting, recruits/upgrades/ownership, friendly fire, central-market distance, respawn, airstrike warning and two-sided damage, shielded heart, barracks destruction, victory, snapshot JSON round trip, army population cap, and temporary soldier conversion.
- The bounded 192-troop simulation was exercised with fighting armies. Spatial buckets avoid a full separation scan for every troop. Snapshot size in the sampled battle was about 17–24 KB; this is a local workload measurement, not a guarantee for school hardware or eight live browsers.
- Existing `v88_party.gd`, `v88_solo.gd`, `v91_changes.gd`: all assertion checks passed. These legacy headless scripts can report audio-playback resources still in use at shutdown; no gameplay script exception was reported. The Battlegrounds test stops its sound players before exit.
- `v90_routes.gd`: passed, including accessibility of the new northern entrance with all town upgrades built. Its search bounds now include the northern forecourt.
- `npm test` in `room_service`: **30 passing tests**, including protocol 26, 3v3/4v4 capacities, public-list settings, matching-version isolation and active-match join rejection.

## Visual checks

Rendered and inspected the team lobby, northern town entrance, personal barracks, central market, Iron Rain hazards and scrollable army upgrade panel using the Compatibility renderer. Five adventure cards fit without overlapping their footer. Army prices/counts, faction colours, the central market, minimap and warnings are visible. The local software renderer reports a V-Sync-support warning; no rendering script exception occurred.

## Remaining classroom validation

Run one actual 3v3 or 4v4 match before broad release. Check all peers' troop movement, buying, damage, respawns, reconnects, victory and replay. Test mobile touch interactions, weaker school PCs and the downloadable host edition. Match length, gold flow and army compositions need human playtesting; deterministic/local checks do not establish competitive balance. The existing browser GPU/WebGL2 requirements remain.

Follow **DEPLOY_V92.md**. Render needs the included service 26 files; no new service or environment variables are required.
