# v102 — Smoothness upgrade

- Retained multiplayer ground chunks reuse drawing commands instead of rebuilding every visible terrain tile each frame. Additional off-screen attack rendering is skipped; damage simulation stays active.
- Remote player motion arrives at 20 Hz and uses a bounded presentation buffer. Teleports reset that buffer; long gaps hold positions rather than guessing indefinitely. Local movement retains its immediate response, with acknowledged collision corrections preserving movement made since the acknowledgement.
- Replaceable world snapshots use a separate unordered WebRTC channel with no retransmissions. Controls, attacks, effects, metadata, recovery and final results remain reliable. Sequence numbers reject stale snapshots; reliable fallback remains available.
- Large states are compressed once per broadcast and fragmented into bounded packets. Missing pieces never produce a partial game state, and incomplete assemblies are capped. Congested replaceable updates are skipped rather than building a long queue.
- Guest attack requests get authoritative cooldown acknowledgements, with an immediate casting pose and sound cue. Damage remains host-authoritative.
- Tova of Lanternmarsh (hero 69): Reed Tap now lands after a short visible extension and retracts promptly, instead of showing a long attack after damage has finished.
- Clockwork Orchard: Hourglass Hart circles players, approaches through clear paths, and uses brief speed bursts; its existing attacks remain.
- Diagnostics now include ping, network bytes, skipped/stale packets, compressed state sizes and partial assemblies.

This is a targeted host-authoritative upgrade, not a complete rollback or dedicated simulation-server rewrite. A different file host cannot by itself remove browser GPU failures. These changes reduce work and queues but do not establish that school Chrome graphics crashes are fixed. Native live multiplayer and school-browser testing remain required.
