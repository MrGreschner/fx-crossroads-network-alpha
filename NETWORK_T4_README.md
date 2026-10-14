# T4 — multi-room Arena reliability playtest

T4 is the separate FX Connections Lab test, built from the latest T3 source. It reuses the main game's 80 official hero definitions and authoritative combat. It does not merge the living-town v167 branch or replace the public main game.

## Install both halves

1. Extract the source ZIP. Copy the contents of its FX_Crossroads folder into the existing MrGreschner/fx-crossroads-network-alpha repository checkout. Do not nest another FX_Crossroads folder inside the repository.
2. Commit and push through GitHub Desktop. Render should redeploy the service using Dockerfile.network. Wait for the build to finish.
3. Open https://fx-crossroads-network-alpha.onrender.com/health. It must say `ready: true`, `build: "T4"`, and `protocol: 3`.
4. Upload FX_Crossroads_Network_Alpha_T4_Web.zip to the existing FX Connections Lab itch.io page as the HTML game. The ZIP already contains index.html at its root. It is an exported game; no manual Godot export is required.
5. Refresh every player's tab. The lobby and diagnostic footer must say T4. A T3 client cannot join this protocol-3 server.

The deployment itself has not been performed by this package. The main FX Crossroads itch page is not the target of this test.

## Hosting capacity is part of the test

Render Free has 0.1 CPU and 512 MB. Source: https://render.com/docs/compute-plans (checked 14 October 2026).

Do not use Free as the capacity baseline for four simultaneous action-game rooms. The measured local authority workload alone exceeded 100 ms per real second under four-room combat, before all gateway/OS costs. Improving code does not create extra CPU quota.

For a serious school test, start with **1 CPU / 2 GB** (`1c-2g`, formerly Standard) to provide headroom. A **0.5 CPU / 512 MB** service (`0.5c-512mb`, formerly Starter) can be evaluated as the lower-cost candidate, but only retain it if the hosted load test stays near 60 Hz and maintains low queue/latency. This is a measured-capacity recommendation, not a purchase made for you. Current pricing: https://render.com/pricing

The service remains one instance with up to four rooms; blindly adding multiple Render instances would break in-memory room routing without a shared room registry. Increase per-instance capacity first.

## What T4 changes

- A common snapshot is encoded/compressed once per room, not separately for every player.
- Arena snapshots omit unrelated envelope fields and dormant component containers. Active official hero mechanics retain their existing snapshot data.
- Reliable visual effects are sent separately, once per connected recipient, and deduplicated by event ID. A slow client's acknowledgement cannot enlarge everybody else's state stream.
- A congested gateway retains only the newest unsent full snapshot. One burst does not trigger the old 64 KB disconnect rule. Sustained non-draining connections have a bounded timeout.
- The server bounds movement backlog to 18 frames. Discarding obsolete input acknowledges it without moving the player; movement catch-up still earns time from server ticks, not packet volume.
- Missing sequence recovery uses bounded replay or an explicit authority-position reset, without disconnecting or accepting client positions.
- Socket disconnects record explicit reasons. Idle lobby heartbeat, abrupt reconnect, reserved seats and resumed identity are tested.
- Browser UI/media helpers do not tick in the dedicated server. Fully disconnected rooms pause during their 60-second resume grace instead of consuming combat CPU.
- Confirmed projectiles follow server positions. They cannot continue indefinitely along a cosmetic launch trajectory during a stall.
- Relative swept projectile collision includes target movement during the tick.
- Instant primary melee (including Ram identity strikes) can check a bounded historical target position matching the client's buffered view, up to 200 ms. Teleports, dead actors and blocked historical movement are excluded. Projectiles are never rewound. Present positions and hit-induced displacement are restored afterwards.
- If authoritative updates stop for 400 ms, local movement/attack prediction stops advancing into an unconfirmed world.
- Match completion and restarting do not build server-side results UI or discard seats. Final snapshots have their own sequence, independent of simulation tick.
- New rooms are refused if measured authority tick delivery is already below capacity, protecting ongoing matches.

## Diagnostics to watch

`/health` reports actual tick delivery, total measured game/poll work per second, snapshot/encoding time, packet size, memory, input backlog, discarded obsolete inputs, coalesced snapshots and disconnect reason counts. Linux hosting also reports process CPU usage when /proc is available; unsupported local containers report null rather than an invented number.

The client footer shows RTT, simulation/snapshot cost, authority Hz, input queue, buffer occupancy and FPS. Browser diagnostic downloads include T4-specific network measurements.

Healthy target for this playtest: authority near 60 Hz, client queue usually in single digits, no continuing growth in memory/queue, no unexpected disconnects, and clear damage registration. Low FPS with healthy RTT/authority is a client rendering problem; good FPS with growing queue/RTT or falling authority Hz is a networking/server problem.

## Repeatable validation

Install Node dependencies in network_service (`npm ci`) and use Godot 4.5.1. Run:

```
python3 network_tests/run_suite.py --godot /path/to/godot
```

For multi-room combat, start the gateway with FX_PROJECT_ROOT pointing to this folder and run network_tests/soak.mjs. Environment controls: FX_SOAK_SECONDS=1800, FX_SOAK_ROOMS=4, FX_SOAK_SEATS=4, FX_TEST_PROTOCOL=3, FX_TEST_URL=ws://127.0.0.1:9080. The soak replays movement, primary/special attacks and match restarts; it records snapshot gaps, input queues, accepted actions and authoritative damage.

Run network_tests/hero_smoke.gd for broad ability/snapshot compatibility. This is a smoke test, not proof of every hero's balance or every uncommon interaction.

See NETWORK_T4_VALIDATION.md and the included JSON results for measured outcomes. Local checks do not certify the current Render deployment, school firewall or physical phones.

## First school test

Start one four-player room, verify build/health, and play moving melee versus projectile heroes. Then add a second room, then four rooms. Run 20–30 minutes with repeated rounds. Record both screens and /health if a hit or connection problem appears. Include the hero names and approximate time so that hit events can be traced.

This still uses WebSocket/TCP for browser compatibility. It handles stale queues and backpressure; it cannot make a stalled TCP connection deliver missing bytes instantly. A WebRTC transport comparison remains a separate measured step if school-network latency persists with healthy authority metrics.

## Moving the successful layer into the main game

Keep network_service, network/server.gd, the Arena adapter, shared movement, world interpolation and projectile reconciliation separate from town/progression logic. Shared combat changes are the guarded projectile collision helper in scripts/object_combat.gd and its player-specific adapter in scripts/arcade.gd. Validate this Arena slice on the school network first, then apply the same protocol/authority separation to co-op and defence one mode at a time. Other modes are not silently migrated by this alpha.
