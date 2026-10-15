# T4.8 validation — 15 October 2026

## Shared combat drawing

All 80 official heroes pass the drawing-position check: owner lookups resolve to local rendered or buffered remote positions in the draw context and physical positions outside it. Explicit attachment policies are checked, including moving Little Menace in mini mode, preserving stationary echoes and checking that draw-time age interpolation does not mutate snapshot records.

A native roster smoke check makes 240 ability-slot calls and compact snapshot round trips. It also verifies newly generated owner metadata for robot jab, ninja cuts and tail slap. An exported browser pass renders all 80 heroes while moving and attempts their three ability slots, for 240 calls, with no JavaScript/engine errors. This is not 240 fully independent end-to-end ability certifications: held abilities and abilities requiring placed objects/targets can remain gated. It does cover the shared render paths beyond the heroes used in class. See NETWORK_T4_8_ROSTER_AUDIT.json and network_tests/t48-roster-web.json.

## Mouse browser combat

Two exported clients, Little Menace versus Ram, connect through the updated T4.8 gateway/authority. The host attacks, shrinks and moves while attacking. Both browser logs confirm mini mode occurred. Clients receive 359/362 states and observe authoritative damage in 195/198 sampled states, with accepted actions, no JavaScript errors, no unexpected closes, and a successful F8 report download. The report identifies server_build T4.8, records gateway RTT, and shows pending-packet queues drained to zero. This container uses software rendering; its FPS is not a classroom performance certification.

## Networking

On the SAME deterministic ordered arrival trace (recurring 120 ms variation), the old T4.7 clock holds 19 measured frames and the new clock holds zero, with an adaptive target reaching 180 ms. Playback is monotonic, never ahead of known server state, and its rate stays in 0.95–1.05. Buffer targets remain within 100–180 ms. This is a synthetic jitter result, not measured school-network improvement.

All constituent network-suite checks pass: combat, local prediction, buffered world, collisions, owned-projectile identity, sampler, idle animation, local view, Twister view, authoritative builds, ability travel, shared anchors, jitter trace, roster smoke, connections/reconnect, actual native clients, latency/jitter, gateway, two native views, short 2/4/8-player load and reliability. The old reliability build-label assertion was updated from T4 to T4.8. The final decode-budget change was checked with latency, gateway probe and reliability follow-ups plus the exported mouse combat test. The final attached-animation timing adapter was checked with the shared-anchor unit and exported roster render pass. See network_tests/t48-validation-summary.txt for the collected outputs.

The gateway test checks the new transport probe separately from authority ping. The 1.5-second ordered TCP-burst/reconnect reliability test passes after the new client decode budget. These checks do not locate the cause of previous classroom delivery gaps or demonstrate a change in real Internet latency.

## Scope and deployment

T4.8 needs the updated server for ownerless legacy flash records and gateway probes. Protocol stays 3; effect metadata is additive. Simulation damage/collision rules, tick rate and hero data are unchanged. Networking changes affect client playback/decode scheduling and add a bounded gateway probe. SERVER_UPDATE_MANIFEST.json lists runtime files changed relative to original T4. The source and server patch are prepared but have not been deployed by the assistant.

No class-scale long-duration smoothness, all matchup balance, production readiness or eliminated-jitter claim is made. Remote visual delay can increase by up to 80 ms nominally under jitter; larger delivery gaps can still cause holds/recovery. See START_HERE_T4_8.md.
