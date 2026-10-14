# Network alpha T2 — shared presentation timing

The lobby and in-match diagnostic footer show T2. This is still the dedicated
Arena alpha, not a migration of all multiplayer modes or a stable-game release.

Changes:
- Server snapshots include actual per-tick actor velocity.
- Remote actors and confirmed projectiles use the same bounded presentation
  lead, estimated from the local unacknowledged input history (maximum 200 ms).
- Removed the extra 75 ms delayed remote-hero rendering in the alpha.
- Brief turn/stop blending, a 120 ms stale-update extrapolation limit, teleport
  snapping, and obstacle resolution bound remote visual prediction.
- Projectile confirmation corrections are rate-limited to avoid backward travel.
- Standard local projectile launch offset matches the authority's 27 px offset.
- Ground-area effects retain their authoritative locations; no predicted damage.

Validation:
- Deterministic two-view close-chase fixture at 150 ms prediction lead checks the
  chase order on both views across repeated snapshots and intermediate frames.
- Remote actor/projectile clock parity, repeated local projectile handoff,
  stop/teleport/stale behavior, and previous local-preview tests.
- Full integration suite: real Godot client, delayed/jittered proxy, reconnect,
  gateway, combat, and short 2/4/8-client load tests. These are local automated
  checks, not a completed school/cellular playtest.

Deploy both the repository/Render server and a fresh Godot Web export to the
FX Connections Lab itch.io page. Reload clients and verify the T2 label.
Test Young Ram and Sunflower in both directions: chase, stop, reverse, shoot,
then cast Earthshaker while moving. Record both screens if possible, with the
RTT/queue footer visible. Severe latency, abrupt remote turns and unusual
abilities still require field testing. No zero-latency guarantee is implied.
