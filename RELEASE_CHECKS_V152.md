# v152 verification

- Realm regression: **263 checks, 0 failures**. Unlock pairs and distinct-clear thresholds; practice restrictions; tutorial shortcut; legal arrivals/enemy placements; Petalbrook seal; ice steering; four moving Shattered Oath guardians; stalled-boss fallback and stun handling; authored co-op stage placement and new artwork.
- Progression regression: **37 checks, 0 failures**. Practice continuation, legitimate clears, discovery, mine-depth requirements and release notice.
- Replay/countdown regression: 0 failures.
- Immersive worlds regression: 0 failures. Authored floors, routes, guardian seals and raft features.
- Co-op regression: 0 failures. Shared four-player raft, movement/attack restrictions, serialized world state, party healing and travelling maypole effects. Older fixture now explicitly skips the real start countdown and provides input actions.
- Room service: **69 tests passed**.
- Native rendering inspected for Grove, Quarry, Sunfield, Rink and Petalbrook. New source SVGs imported and cached.
- ZIP CRC, fresh-extracted import and realm regression checked before delivery.

These are local Godot/service checks. No deployment has been performed. School-device FPS, live Chrome/WebGL stability and actual itch.io/Render connectivity must be checked on the published build; local rendering used a software graphics driver.
