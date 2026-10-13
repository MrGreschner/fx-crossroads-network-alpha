# Network alpha 1 — measured results

Measured on the development machine on 2026-10-11 using Godot 4.5.1 and Node 24.19.0. These are local prototype measurements, not cloud/school performance guarantees.

| Players | Core tick p50 (ms) | Core tick p95 (ms) | Core tick maximum (ms) | Download KiB/player/s |
|---|---:|---:|---:|---:|
| 2 | 0.793 | 1.137 | 1.833 | 38.5 |
| 4 | 0.696 | 0.973 | 1.088 | 40.7 |
| 8 | 1.059 | 1.435 | 1.496 | 44.7 |

Each count ran for 4.3 seconds with all clients sending movement. 86 snapshots were observed in each run. Tick timings cover the combat/physics update, excluding snapshot serialization/compression and gateway scheduling. 60 Hz has a 16.67 ms tick interval; the whole deployment, not only this measured region, must fit that budget.

The actual Godot client passed both a direct connection and the public-style Node gateway. A seeded proxy added 40 ms one-way delay in each direction, ±12 ms jitter, and occasional 160 ms ordered-transmission stalls. The final client metrics were:

- Final sampled RTT: 116 ms
- Largest movement reconciliation error: 0.701 pixels
- Corrections above the one-pixel reporting threshold: 0
- Snapshots received during the scripted client run: 71

Authority tests passed for original melee damage, cooldown-spam rejection, charged projectile release/damage, malformed input, bounded projectile presentation, eight-player admission, input acknowledgements, stable projectile identity/velocity, rejected teleport commands and same-identity reconnect. The full reusable suite is network_tests/run_suite.py.

Limits: short runs; no exported Safari/Chrome or slow school-PC measurements; no real WAN packet-loss measurement; no long concurrency soak; no all-hero parity matrix; no other-mode migration yet. Dockerfile is provided, but the Docker image was not built here. The native Godot/Node gateway launch was exercised.

Production gates: private deployment, school-network comparisons, 30+ minute sessions, repeat 2/4/8 player combat with different heroes, then multi-room soak and mode migration. Reduce static/repeated state further and benchmark a datagram path if real WebSocket loss causes head-of-line stalls.
