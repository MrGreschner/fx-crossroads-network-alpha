# FX Crossroads — Network Alpha T4.17

T4.17 is ready for installation and the next school playtest. Update BOTH the networking alpha on itch.io and its existing Render service. This is separate from the v169 main game; keep that game and its public page unchanged.

## Changes

- Post-match results now offer **Back to T4 menu • Host / Join**, replacing the town and legacy-party exits in this alpha. This leaves the finished room and clears its reconnect state, while retaining the server address and display name. Students can host or join again without refreshing the browser. Other alpha town-exit shortcuts also return to this menu.

- Repeated floor tiles merge into larger repeating rectangles. Tile scale, artwork, flowers and collision remain consistent. The renderer no longer submits a separate floor quad for every tile. In an isolated 1280×720 plain-floor comparison, floor quads fell from 384 to 6; uniform forest with flowers fell from 401 to 23, with draw calls falling from 35 to 12. Mixed grass/forest paths fell from 399 to 159 quads. These are terrain measurements, not reductions for the entire frame or promises of a particular FPS.
- Reconciliation applies the complete server position repair to prediction immediately. Small repairs retain a short, decaying visual offset for the character and camera, instead of modifying prediction in several partial steps. This avoids later snapshots correcting an unfinished repair. Large repairs, respawns and teleports reset the view. Decay follows render time rather than frame count. Hit detection remains server-owned.
- The render shell only reapplies viewport dimensions when size or quality actually changes. Existing Auto resolution tiers and F6 Full override remain available.
- Reports add browser animation-frame gaps, supported long-task measurements, visibility history, client frame gaps, visual correction size, floor geometry counts and viewport resize counts. The dashboard exposes these fields. A state stall coinciding with a large client frame gap is distinguished from a state-delivery gap during regular frame updates. These timing contexts do not prove whether a connection, browser, driver or school network caused a delay.
- Client, server, dashboard, health response and newly downloaded combined match reports use T4.17 / FX_T417. Existing historical reports retain their original versions. No database reset or SQL migration is required.

## Install the server update

1. Download and extract `FX_Crossroads_Network_Alpha_T4_17_Server_Update.zip`.
2. Open `UPLOAD_TO_GITHUB`. Upload the CONTENTS of that folder into the ROOT of the existing GitHub server repository, preserving the `network`, `network_service`, `scripts`, `web` and `assets` paths. Do not upload the ZIP or create an `UPLOAD_TO_GITHUB` folder in the repository. Keep existing files outside the patch.
3. Commit the uploaded changes. In the existing Render game service, choose **Manual Deploy → Deploy latest commit** if automatic deployment does not start.
4. Keep the current service, paid instance, database and environment variables. The Dockerfile remains `Dockerfile.network`.
5. After deployment succeeds, check [server health](https://fx-crossroads-network-alpha.onrender.com/health). It should report `ready: true` and `build: T4.17`.

The patch contains 75 runtime/configuration files plus a file-hash manifest and this guide. It includes the earlier T4.16 dependencies, and was applied locally to a clean T4.13 project for the final server test. The hosted Render deployment must still be performed on your account.

## Install the itch.io alpha

Upload `FX_Crossroads_Network_Alpha_T4_17_Web.zip` to the existing networking alpha page, replacing the previous Web build. Keep it configured as an HTML game. `index.html` is at the ZIP root. Include the complete ZIP: the new `frame_timing.js` file is required alongside `reports.js` and the engine files.

Reload the game on every device. The lobby should say **T4.17**, and in-game diagnostics should say **T4.17 • server T4.17**. Do not compare results until both labels match.

The editable source ZIP is for Godot 4.5.1 development and future exports. It is not the itch.io upload. The Web package uses the same Godot 4.5.1 Web engine as T4.16 with the newly exported project pack and updated page/scripts.

## Next school test

Use the same integrated-graphics lab and keep the teacher's RTX computer as a comparison. Leave F6 on **Auto**. Run a two-player match, then an eight-player match for at least three minutes each. Keep the hero selection as close as possible to the T4.16 test: two Nullweavers, Robot, Magnet, Twister Mage, Garrick, Dawnblade and Goaltender for eight players.

Keep tabs visible and devices awake. Include ordinary movement, dashes, melee and ranged attacks. Note whether a problem is low FPS, character/camera snapping, delayed attacks or a recovery message. Download the combined match report from the dashboard after each test. Database reports remain the primary evidence; F8 is a backup.

## Validation and limits

- Forty local regression checks passed across the run logs: combat, 80-hero ability coverage, projectile roster, collision, prediction, prepared movement, dash replay, local/remote presentation, latency/jitter, real Godot clients, reconnect, gateway, 2/4/8-player load, goalie expiry, Gladiator enemies and soccer travel, plus the new reconciliation regression.
- New reconciliation checks verify immediate prediction repair, continuity of the visual position, no repeated correction for identical later snapshots, frame-rate-independent smoothing, teleport handling and both stall timing contexts.
- Exported-browser checks passed for terrain coverage and original/merged pixel comparisons in six scenarios. Terrain comparisons exclude the unrelated Student/Teacher overlay in the top 40 pixels. Mouse and touch mapping passed at 100%, 85% and 70% raster resolution.
- Native mobile text-entry emulation passed independent fields, room-code limits, resizing, real server join and hiding inputs during play. Physical iOS/Android keyboard appearance still requires a real-device check.
- One real exported browser with seven network peers passed eight-player combat and a six-second forced loss of state snapshots, recovering the same player identity and match. This used software rendering, not a physical school Intel GPU.
- Browser timing captured an intentionally introduced 180 ms main-thread long task and its frame gap.
- SQL-backed ingestion/export retained the new diagnostic fields, matching T4.17 release labels and the FX_T417 match filename.
- The cumulative patch on a clean older server project passed eight-player combat for 60 seconds: 1,202 state updates per client, no reported errors, no unexpected disconnects, all clients dealt damage, local RTT p95 18.3 ms and snapshot-gap p95 54.3 ms. One normal completed-round restart occurred; this is not a server restart.

- A focused post-match regression passed: the new result button closes results without a scene/browser reload, clears the old room and reconnect state, preserves address/name, and allows both Host and Join to create fresh connections.

These checks establish local functionality and package compatibility. They do not establish 60 FPS, eliminate every correction, or reproduce the school's hardware and network. T4.17 still needs the next on-site test before the alpha is finalized or merged into v169.
