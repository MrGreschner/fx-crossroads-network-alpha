# v101 — Multiplayer connection cleanup and diagnostics

## Lobby fixes
- Host-only **Kick** buttons beside each human guest. Removes the guest immediately, closes both WebRTC channel and peer, and frees their seat. Guests cannot kick the host or players in other rooms. Bots use the existing match-setting controls.
- A server departure is authoritative even if the old direct connection still reports open. Player positions, hero choices, team, food, lobby builds and recovery state are removed together.
- Duplicate join notifications cannot create duplicate seats. Late signaling from removed room members cannot recreate a link.
- A guest who never completes hero registration is removed after 30 seconds in the waiting lobby. This is separate from the existing 45-second recovery window for previously connected players.
- An expelled guest receives a clear message and their old room cannot be resumed. They can deliberately join again; this is a seat-removal control, not a ban.

## Multiplayer workload
- Process at most eight received gameplay packets per peer and 24 total per frame; rotate which peer is serviced first to avoid starving later seats. Packets retain reliable ordering and are processed on subsequent frames, rather than dropping gameplay events. Persistent overload may still create latency; report queue depth makes this visible.
- Limit signaling processing to 24 messages per frame.
- Only send all-hero random-build data when random-hero arena mode actually needs it.
- Explicitly close channels and peers when leaving, being removed, repairing a link, or destroying the scene; also close the separate public-room browser socket.
- Reuse lobby panel styles instead of constructing new style resources every drawn frame.

## Crash investigation
The recurring WebGL2 failure has NOT been reproduced on school hardware or established as fixed. These changes address observed connection bugs and reduce potential multiplayer pressure. Graphics-context loss may reflect a browser/GPU/driver reset, not missing hardware support. Moving the room service to another provider does not replace the client renderer.

Reports now record graphics renderer/version when exposed by the browser, render dimensions, texture-size limit, optional JavaScript heap size, network link count, queued incoming packet count and processed packets. Reports remain local and are not automatically uploaded. The Web export's early crash recorder is now synchronized with the runtime recorder, including its diagnostics-enabled setting. A graphics-loss overlay is shown only once.

Export and test several consecutive multiplayer matches on the affected PCs. If it recurs, download the report BEFORE restarting Chrome and provide that file. Native Windows multiplayer remains an alternative browser-independent rendering path, subject to the project's existing native WebRTC setup.
