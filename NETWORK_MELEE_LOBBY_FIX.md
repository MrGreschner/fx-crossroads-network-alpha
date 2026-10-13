# Alpha 1 melee and lobby hotfix

Melee effects carry the attacker identity and follow its rendered position for the effect lifetime, including predicted local movement and smoothed remote movement. Attack direction, reach and server damage resolution remain unchanged; stationary area effects stay in world space.

Keep-alive pings now run in the lobby as well as matches. Lobby disconnects can resume their existing seat. Repeated Host/Join clicks while connected no longer replace the connection. Full-room and started-match errors are distinct.

Install all updated files and restart both server and clients. Includes the previous keyboard/mouse bindings fix.

Regression: actual Godot client waits 12.5 seconds in lobby before match start (beyond the former 10-second timeout); melee anchor assertion; combat, eight-player connections/reconnect, latency/jitter, gateway and load suite.
