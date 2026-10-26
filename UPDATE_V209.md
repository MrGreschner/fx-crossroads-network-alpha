# V209 — Lantern thieves and foreshadowing darkness

## Lantern thieves

Wickpinch Sneaks now close all the way into pickup range when the shared lantern is on the ground, grab it and run away with it. The previous logic used the normal melee stopping distance of65px while pickup required less than48px, leaving them stalled outside pickup range.

Thieves use a dedicated approach/grab action with a clear-path check. They can still steal a player-held lantern, but cannot take it from another thief. Escape destinations persist, so reaching a corner sends the thief across the room rather than oscillating in place. The lantern light and fallback position follow the carrier. Defeating the thief drops the lantern at its location; a living player then retrieves it with E. Existing protection after knockoff/drop is retained.

The server remains authoritative. The existing shared-lantern snapshot sends ownership, position and fuel to co-op clients; no new inputs or network protocol are needed.

## Room-edge darkness

Darkness now forms a soft room-anchored gradient: the centre keeps the original depth progression, while edges become darker and corners provide the strongest preview of deeper floors. This is anchored to the cave room, so moving the camera does not move the dark corners around with you.

The corners preview up to six floors deeper. Around floor29 they already approach the darkness the centre reaches at floor35. Once fully deep, the room remains dark and the shared lantern becomes essential. The lantern still cuts through the darkness, with the same wider radius on the ground, smaller carried radius and fuel behavior from floor60. The lava epilogue beyond100 remains bright.

The renderer uses a small cached room-gradient texture updated only when floor/room geometry changes, four clipped regions and one81-vertex batch using the original smooth lantern mask. No extra viewport, real-time lights or per-frame image generation is added. The overlay stays before HUD rendering so interface readability is preserved.

## Validation

Targeted checks cover ground/carried theft, closing the old dead zone, escape movement and persistent destinations, single-owner behavior, defeat/drop/E recovery, co-op state and client authority restrictions. Darkness checks cover depth progression, corners/edges, opacity bounds, floor35/floor101 behavior, cached resources and mesh indices.

Existing100-floor Descent, combat and navigation checks plus network-handler regressions are run. Native views are inspected at multiple depths with a carried, grounded and stolen lantern. The dedicated server entry scene is checked for successful startup. Character definitions, database/backend logic, accounts, saves and keys remain unchanged. Real-device/browser and live multiplayer playtesting remain.

## Deployment

Deploy the V209 server update to Render first, retaining the existing database, persistent data, environment variables and keys. Then upload the web ZIP to itch.io and hard-refresh. Use the editable ZIP to debug in Godot. Nothing has been deployed automatically.
