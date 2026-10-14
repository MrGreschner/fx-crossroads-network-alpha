# T4 validation — 14 October 2026

T4 is a runnable Arena playtest, not a certification of the live service or school network. Both client and server must be updated together to protocol 3. No GitHub push, Render plan change or itch upload was made during this build.

## Completed checks

| Check | Observed result |
|---|---|
| Full network regression suite | Passed: authoritative combat, input prediction, buffered remote world, actual native clients, latency/jitter, gateway, two native views, room connections, load checks and reliability |
| Final source: 16 simulated players / four rooms / 90 seconds | Passed all final assertions; zero unexpected closes/errors; every player accepted attacks and dealt damage; one round restart per room |
| Final run timing | Snapshot gap p95 55.0 ms, maximum 104.5 ms; round-trip p95 17.4 ms; maximum observed client input queue 4 |
| Capacity: 32 simulated players / four rooms / 120 seconds | Passed; zero unexpected closes/errors; every player dealt damage; rounds restarted; gap p95 56.6 ms, maximum 133.7 ms; RTT p95 20.6 ms; maximum client queue 10 |
| Two exported web clients | Passed; 285/284 snapshots, 17/10 accepted attacks, authoritative damage visible in 198/197 snapshots, no JavaScript errors or unexpected closes |
| Loss/recovery | Idle lobby heartbeat, 1.5-second TCP input burst, bounded movement, explicit history reset without teleporting and abrupt reconnect with resumed identity passed |
| Targeted authority checks | 12 collision/history/compaction/membership checks passed, including moving targets, stacked-player identity and expired-host ownership handoff |
| Official heroes | All 80 hero JSON definitions byte-for-byte unchanged from T3; 240 broad ability calls plus compact snapshot roundtrips passed |
| Web export | Godot 4.5.1 export succeeded; exported game exercised in Chromium |

Browser tests used software rendering in a container. Observed 11–12 FPS is not a hardware frame-rate measurement and does not certify client rendering performance on school devices. The test proves browser loading, protocol, combat and connection behavior only.

The short bandwidth regression was approximately 18.4/20.8/24.8 KiB per player per second for 2/4/8 players, compared with T3's approximately 38.7/41.2/45.2. These are short single-room synthetic comparisons, not WAN throughput promises.

## 30-minute endurance evidence and limitations

The four-room, 16-player combat workload reached its requested 1,800-second duration. The final captured runtime sample at 1,793 seconds recorded 570,652 client snapshots, zero unexpected closes, 16 connections, no authority or gateway disconnect reasons and 60.1 Hz authority delivery. Across 180 samples, median authority delivery was 60.0 Hz. Last authority memory was approximately 119 MiB.

The run was not consistently smooth: minimum sampled authority delivery was 14.4 Hz; maximum tick work was 561 ms; the observed client acknowledgement queue peaked at 107. The server discarded 10,416 obsolete input frames while recovering. Other Godot/browser validation processes shared the host during this run. That makes the spikes unsuitable as an isolated capacity benchmark, but they remain real stalls in this evidence and must not be hidden. No disconnect was observed through them.

After the workload, the JavaScript test reporter failed because it spread too many snapshot gap samples into Math.max. Its final assertions and per-player summary did not run. The reporter now uses a reduction without that argument limit; the final 90-second rerun above passed and generated its complete report. The retained long-run JSON contains every recoverable health sample; it deliberately does not invent missing percentiles or per-player final totals.

The endurance run covered the networking core before the last targeted collision, client terrain and ownership refinements. Those final changes were covered by the full suite, hero/collision tests, 90-second multi-room rerun and exported-browser test. The final package has not completed a second isolated 30-minute run.

## Hosting and acceptance

The isolated final multi-room samples measured roughly 250–360 ms of authority work per real second. Render Free's 0.1 CPU allows only about 100 ms of CPU time per second on average; the measured authority work alone exceeds that, before gateway overhead. Start the school playtest on 1 CPU / 2 GB; consider 0.5 CPU only after measuring it. Work-duration measurements are not an exact CPU profiler, but are sufficient to reject assuming the Free quota can sustain this workload.

Deploy both halves following NETWORK_T4_README.md. Check /health says ready true, build T4 and protocol 3. Start one four-player room, then two, then four, with repeated rounds for 20–30 minutes. Record authority Hz, input queues, RTT, FPS and disconnect reasons. A pass needs sustained near-60-Hz authority, bounded queues, no unexpected disconnects and damage registering against moving targets on actual student devices.

No test here reproduces the school firewall, geographic latency, shared Wi-Fi or live Render CPU quota. WebSocket still uses TCP; client/server queue recovery cannot eliminate transport stalls. The package provides a reusable authoritative Arena layer and diagnostics for the next deployment, not an assurance that the unmodified T3 hosting will become smooth.

## Included evidence

- NETWORK_T4_VALIDATION.json: structured summary.
- network_tests/t4-final-90second-soak.json: final source multi-room run.
- network_tests/t4-32player-capacity.json: short capacity check.
- network_tests/t4-30minute-runtime-evidence.json: retained long-run health samples and reporting limitation.
- network_tests/t4-web-clients.json: exported browser clients.
- network_tests/benchmark-results.json: short regression measurements.
- network_tests/t3-multiroom-baseline.json: locally reproducible T3 comparison. T3 could also handle four rooms on this faster local host; that does not reproduce the constrained live service.

Research references: https://render.com/docs/compute-plans ; https://render.com/docs/free ; https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html ; https://docs.godotengine.org/en/stable/tutorials/networking/webrtc.html
