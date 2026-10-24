# Crossroads: Realms Beyond — V198.47

Build **V198.47-living-town**. Godot 4.5.1; protocol 11 unchanged. Includes all V198.46 changes.

## Why the town felt dormant

The shared real-world clock was working, but most residents reached their work destinations within seconds and then stayed hidden inside buildings until lunch. Saturday’s makers’ fair did not begin until 11 am, leaving very little visible activity at 8 am.

## What changed

Five existing residents now run daytime errands across the central square/service streets, western market and exchange, southern neighbourhood/marina and east-bank river walk. Their departures are staggered. They walk between stops, pause for short visits and carry the existing activity props. Two other residents make quieter overnight rounds and take daytime rest. The camp traveller and weekly gatherings, including tea, games, Sunday stories and Wednesday music, remain part of their schedules.

There are still **21 civilian residents**: no additional agents, particles or lighting systems. Five collision-aware circuits are computed once and reused, with street weighting and existing navigation. Sampling positions does not run a new path search. Complete circuits fit the available schedule window so departures begin at the preceding route’s finishing position.

## Validation

1,386 targeted checks passed: sampled outdoor coverage across all seven days and eleven times per day, Saturday 8 am walkers, central-town movement during the following minute, circuit waypoints/interpolated positions, unchanged population, cache reuse, night-worker rest and retained special gatherings. At Saturday 8 am all five errand residents are outside and two are actively walking. At least two civilians are outdoors at every sampled time; daytime samples have at least five.

Native visual checks cover Saturday 8 am, the following minute and the southern town. Packaged-runtime checks and archive integrity/parity checks are included in the validation file. Real classroom-device playtesting remains; these are schedule and functional checks, not a measured low-end-device FPS improvement.

## Manual deployment

Deploy **Crossroads_v198_47_Server_Update.zip** to Render first, preserving the existing environment variables, accounts, database, saves and keys. Then upload **Crossroads_v198_47_Web.zip** to itch.io as the HTML game. **Crossroads_v198_47_Editable.zip** contains the complete editable project.

V198.47 is cumulative: use these files instead of V198.46. No new database migration is introduced beyond V198.46’s additive catch/restart tables. No live deployment or production-data change was performed.
