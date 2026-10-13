# v145 verification

Godot 4.5.1 headless checks:
- 47 targeted checks: relocated entrances are walkable; Ram Descent interaction follows the cave; journal prompts removed without breaking archived entries; suggested marks respond to missing evidence without writing grades; normal and Media zoom; touch restore; top-button containment and non-overlap at 1280×720 and 896×414; grand stadium threshold; six stations; progress gauges; walking out returns to town; persisted access removal.
- 24 education, 54 learning, 159 town/combat, 44 foundry, 43 Market and 22 runtime checks passed with isolated temporary profiles. No official hero attack definitions were changed.
- Terrain index retains exact tile results on the revised town path graph and reduces cold-build polygon checks by over 98% relative to scanning all polygons.
- Final startup and parser checks, archive CRC, complete fresh extraction and room-service/hero-data equality checks are included in packaging verification.

Automated checks examine scene/UI geometry. Native visual screenshots could not be captured in this execution environment because an X11 connection was unavailable. Web/Windows exports require a target-device visual spot check before publication; no claim of browser/device performance certification is made.
