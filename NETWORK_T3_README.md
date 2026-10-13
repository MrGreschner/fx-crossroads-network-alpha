# T3 — buffered Arena networking and shared attack artwork

This package replaces T2. The lobby, diagnostic footer and /health endpoint
identify T3. Wire protocol is now 2: an older client receives an explicit version
error rather than silently joining a server with different presentation rules.
Deploy BOTH the complete repository to Render and a fresh Godot Web export to
the existing FX Connections Lab itch.io page. Refresh both clients afterward.

## What changed and why

T2 extrapolated remote heroes ahead using a per-client estimate. Instant stops
and reversals made those estimates incorrect. It also restarted correction
blends whenever packets arrived. The earlier tests did not adequately measure
what a moving opponent looked like on two clients at once.

T3 uses one bounded snapshot buffer, indexed by server simulation ticks, for
remote players, confirmed projectiles, Ram's horn animation, Earthshaker and
shared event effects. Playback advances monotonically, usually about 100 ms
behind the latest server state, with small speed adjustments for buffer drift.
It holds the latest known world during a stall rather than inventing continued
remote movement. Local movement still predicts immediately and reconciles
unacknowledged inputs against server acknowledgements.

Projectile births carry their simulation time. A remote seed can be reconstructed
back to its launch within the interpolation interval, rather than first appearing
at its already-advanced packet position. Local seed previews and server-confirmed
seeds call the SAME artwork renderer. No temporary large green-circle renderer
is used. Straight local projectiles retain their cosmetic launch trajectory at
confirmation; the server still decides hits, damage, rejection and despawn.

Server movement inputs earn credit from server ticks, not packets. Delayed
batches can catch up by at most two steps per tick with bounded saved credit.
Attacks execute at their corresponding movement input step. This drains jitter
backlog without giving a flooding client an unlimited movement budget.
Headless server polling is capped at 60 FPS; native client polling is capped at
120 FPS. This accompanies the 60 Hz simulation and 20 Hz
snapshots, to avoid an uncapped process loop consuming shared server CPU.

## Verification

Run network_tests/run_suite.py --godot PATH_TO_GODOT.
Checks cover server combat/cooldowns, time-budget catch-up, movement validation,
projectile confirmation, rejection, burst-member identity, server-tick interpolation,
turns/stops, projectile births/despawns and stale snapshots. Two actual Godot
clients run simultaneously through an ordered latency/jitter/TCP-stall proxy,
reverse direction repeatedly and fire seed bursts. The test measures displayed
opponent frame displacement, preview artwork metadata and remote seed rendering.
Additional tests exercise eight-player connections, idle lobby heartbeat,
reconnect/resume, a real Godot client through the gateway, and short 2/4/8-player
load runs. Results are local automated checks, not proof of school/mobile production
performance or broad compatibility across every hero's unusual ability.

## Field test

1. Verify /health reports protocol 2 and build T3. Verify both clients show T3.
2. Play Ram versus Sunpetal on PC and cellphone (landscape).
3. Walk together, stop, reverse, move around obstacles, then attack while moving.
4. Fire seeds in both views. Their artwork should be consistent from first appearance.
5. Cast Earthshaker while moving. It is a fixed ground damage area, not an aura.
6. Record both screens with RTT, queue, FPS and buffer diagnostics visible.

The free server remains appropriate for a small evaluation; its shared CPU and
cellular/Wi-Fi packet stalls remain measurable limitations. WebSocket uses TCP,
so delayed delivery can still pause remote playback. T3 repairs presentation and
backlog problems; it does not promise zero network latency or introduce a new
WebRTC/UDP service. A future transport change must include browser support,
TURN/firewall testing and measured comparison rather than being treated as a
substitute for correct prediction/interpolation.

This remains the separate Arena networking alpha. It does not change the stable
main game, save profiles, or migrate all other multiplayer modes automatically.
