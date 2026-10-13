# Architecture and protocol 1

The public WebSocket gateway owns TLS-facing transport and health reporting; a private headless Godot process owns matches. The gateway never computes damage. A room creator has start/hero-selection permissions but no simulation advantage. The existing room_service continues serving the released game.

Each private room has one network/arena.gd simulation instance inheriting the current arcade.gd combat. The server runs a bounded 60 Hz input step and broadcasts at 20 Hz. Four rooms and 64 WebSocket connections are configured as prototype caps, not proven production capacity. Each room supports up to eight players. Match state lives in RAM; a server restart ends its test matches.

Input protocol: clients send two 60 Hz frames per movement packet. Frames carry monotonic sequence, normalized direction, aim angle and held-button flags. The server ignores client elapsed time and processes at most one movement frame per actor per physics tick. Clients retain at most 180 predicted frames; server input queues are capped at 120. Invalid sequence gaps/overflow close the connection instead of accumulating seconds of lag. Actions carry a separate sequence and the movement sequence from which they were aimed. Actions execute in order after that movement frame is accepted. The original combat code checks health, ability level, charge, cooldown and collision.

Snapshots are independently recoverable JSON compressed with GZIP in binary WebSocket frames. Welcome/start/lobby/action acknowledgements are text frames. Each state has a monotonic server tick and each player has a processed-input acknowledgement. Clients keep only the newest pending state while draining bounded packet batches. Effects carry monotonic IDs, are replayed until acknowledged, and are retained within a 256-event cap. A normal client never applies local damage.

Movement reconciliation replays unacknowledged inputs from the authoritative point. Small corrections are spread over physics ticks; corrections over 80 pixels snap. Remote actors use a short interpolation buffer. Basic shots carry stable IDs, position, velocity, owner and originating action sequence; their display advances between snapshots, with at most 120 ms of extrapolation. Local ghost previews are cosmetic only. Specialized projectile/area/hero systems need individual parity tests; none is approved solely because the common path passed.

Protection is session-scoped: private code, unpredictable player ID, unpredictable resume token, server-selected ownership, packet size/queue/rate limits, and a command whitelist. Clients cannot change health, assign another player’s hero, execute Game Dev commands, or submit absolute movement positions on this path. This is not a school authentication/subscription system. Do not expose development commands or raw authority port as administration APIs.

WebSockets are used for the first browser/native-compatible test. They are reliable/ordered, so packet loss can delay later messages. Small packets, compression and bounded queues reduce accumulated lag but do not remove this transport property. Compare actual school-network measurements before a production transport decision; a server WebRTC/datagram gateway may be the next step for replaceable movement snapshots. Godot’s official networking and dedicated-server references:

- https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- https://docs.godotengine.org/en/4.3/classes/class_websocketpeer.html
- https://github.com/godotengine/godot-docs/blob/master/tutorials/export/exporting_for_dedicated_servers.rst
