# FX Crossroads — dedicated networking alpha 1

This is a separate development copy of v165. Deploy v165 to students on Monday as planned. Do not replace the public game or its existing Render room service with this alpha.

## What is built

- A Godot authority process runs actual Arena combat at 60 physics ticks/second. The browser which creates a room is a controller/client, not the simulation host.
- Both sides use a shared movement routine. Clients predict movement immediately, keep input history, and replay unacknowledged frames after server correction.
- Server-owned positions, health, cooldowns, collisions and attacks; client position/teleport packets are not accepted.
- Snapshots at 20 Hz, compressed binary frames, bounded network queues, event acknowledgement and replay.
- Stable projectile identities plus velocity for continuous travel between snapshots. Local basic-shot previews do not deal damage and disappear on rejection/confirmation. The common combat-projectile renderer also advances between snapshots.
- Private code rooms for 2, 4 or 8 players. Resume tokens keep a disconnected player’s seat for 60 seconds; clients automatically retry for 15 seconds.
- A Node gateway provides the public WebSocket endpoint and /health; the Godot combat port can remain private behind it.
- All test progress is temporary. This project has a separate application name and disables profile progression during network tests.

## Quick local test: no hosting purchase needed

1. Extract this project into its own folder. Open project.godot in Godot 4.5.1 and let imports finish. The main scene is the network test lobby.
2. Run a second Godot process as the authority. In a terminal, substitute your Godot executable and the extracted project folder:

```
godot --headless --path "YOUR_PROJECT_FOLDER" res://network/server.tscn
```

3. Run the client from the editor. Set its server field to ws://127.0.0.1:9081 for this direct local test. Choose a hero and Host test room.
4. Run another client instance, enter the displayed code and choose Join test room. The creator then presses Start match. Every human is a client; the separate headless process runs combat.
5. Stop the headless process when finished. It does not create public rooms on the existing service.

For a LAN native-client test, use the server computer’s LAN IP instead of 127.0.0.1 and allow its test port on the local firewall. The default gateway address in the client is port 9080; direct Godot uses 9081.

## Gateway and private cloud deployment

The full project is required by the authority. Uploading only room_service will not deploy this server.

With Node 24 and Godot 4.5.1 installed:

```
cd network_service
npm ci
npm start
```

Set GODOT_BIN to the actual Godot executable if it is not on PATH. The gateway defaults to port 9080 and starts the private authority on 9081. Open http://127.0.0.1:9080/health to check readiness, then connect native clients to ws://127.0.0.1:9080.

For a separate private Docker service, use this project as the build context and Dockerfile.network as the Dockerfile:

```
docker build -f Dockerfile.network -t fx-authority-alpha .
docker run --rm -p 9080:9080 fx-authority-alpha
```

Dockerfile.network pins Godot 4.5.1 and verifies the downloaded archive’s SHA-256. The equivalent Node/Godot gateway was tested directly; a Docker build was not executed in this environment.

On a hosting service which accepts Docker, create a NEW test service, choose this Dockerfile, set PORT to the service’s expected port, and use /health for its health check. Preserve the existing room-service deployment. Use an HTTPS/TLS public endpoint and put its wss:// address in the alpha clients. An itch.io HTTPS page needs a secure wss:// connection; localhost ws:// is for local/native tests. Select an always-running test instance and measure ping from the school before selecting a long-term region/plan. No service was purchased or deployed by this update.

Export this alpha to a separate private itch.io test page and separate native download after the test server is deployed. Keep the existing presets’ web/*.js include and keyboard option. Protocol 1 alpha clients connect to the new authority, not the current room service. The old v165 version-check component is disabled in this isolated network scene.

## Repeat the checks

Install the network_service dependencies, then run:

```
python network_tests/run_suite.py --godot "PATH_TO_GODOT"
```

The suite runs original melee/charged combat checks, malformed-input validation, real eight-player socket tests, an actual Godot client, a delay/jitter/stall proxy, reconnect tests, the HTTP/WebSocket gateway, and 2/4/8-player load checks. Test userdata uses a temporary directory. Logs go to network_tests/runs. Benchmark results are JSON, and NETWORK_ALPHA_RESULTS.md explains the measurements and limits.

## Remaining gates before replacing live multiplayer

This is the first Arena milestone, not the completed migration of every game mode. All official heroes are selectable, but the automation covers Young Ram melee, Diamond Scout charge/release damage and Star Navigator projectile/movement. Check the full hero matrix, including special movement, summons, status effects and charging visuals, on native and exported browser clients.

Next: private school-network tests on slower machines and phones; longer concurrent-match soak tests; refine bandwidth and transport under actual packet loss; test every hero; then migrate co-op realms, Descent, Gate Defence and Battlegrounds to this same authority path. The original browser-host multiplayer is still present elsewhere in this development copy. School accounts, subscriptions and class services remain a separate later backend task.

Network latency and low-end rendering cannot be eliminated by a hosting purchase alone. This alpha establishes a measurable replacement path; it is not yet a production guarantee.
