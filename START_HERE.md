# FX Crossroads — T4.13 playtest

This release needs BOTH the new itch.io Web ZIP and the server files. The database is a separate Render resource; upgrading your game service's CPU does not create it.

## 1. Update the GitHub server files

Extract `FX_Crossroads_Network_Alpha_T4_13_Server_Update.zip`. Its `UPLOAD_TO_GITHUB` folder contains the replacement files with their correct folders.

On GitHub's website, open your repository's MAIN PAGE (where `project.godot`, `network`, `scripts`, and `network_service` are visible). Choose **Add file → Upload files**. Drag the CONTENTS of `UPLOAD_TO_GITHUB` together into that page: the `network`, `scripts`, and `network_service` folders. Commit the changes to the branch Render uses.

Keep those folder paths. Do not put `server.gd` or `gateway.mjs` loose at the repository root. Do not upload the outer ZIP, the `UPLOAD_TO_GITHUB` folder itself, or `node_modules`. You are replacing selected files in the existing complete repository; this small update ZIP is not a standalone game project.

Check these files in GitHub afterward:

- `network/server.gd` and `network/arena.gd`: T4.13.
- `network/projectile_view.gd`, NEW `network/projectile_recipe.gd`, `network/world_view.gd`, `network/diagnostic_hud.gd`.
- `scripts/arena_world.gd` and `scripts/object_combat.gd`.
- `network_service/gateway.mjs`, `package.json`, `package-lock.json`.
- NEW `network_service/reporting.mjs`, `reports.sql`, `reports.html`, `dashboard.js`.

The manifest lists every required file and its checksum. Leave the existing `Dockerfile.network` in place. It already runs `npm ci`, which installs the new PostgreSQL dependency from the updated lockfile.

## 2. Connect the database in Render

1. In Render, create a **Postgres** database, for example `fx-playtest-reports`. Choose the SAME region as your existing game service. Review the plan/retention shown by Render before creating it; the game-service subscription is separate from the database plan.
2. When the database is ready, copy its **Internal Database URL**.
3. Open the EXISTING game Web Service → **Environment**. Add:

| Key | Value |
| --- | --- |
| `DATABASE_URL` | The database's Internal Database URL |
| `REPORT_ADMIN_PASSWORD` | A new private password of at least 24 characters; use a password manager |
| `REPORT_SIGNING_SECRET` | A separately generated random secret, at least 32 characters |

Do not paste these values into GitHub, itch.io, game settings, screenshots, or chat. Keep the administrator password so you can sign in.

4. Save the environment changes and deploy the latest commit. Use **Manual Deploy → Deploy latest commit** if needed. Restarting the old deployment does not select the new GitHub commit.
5. Wait for Render to report **Live**.
6. Open `https://fx-crossroads-network-alpha.onrender.com/health`. Confirm `build` is `T4.13`, `ready` is `true`, and `reporting.ready` plus `reporting.admin_configured` are `true`. If your service uses a different hostname, substitute it in these URLs.

The server creates its diagnostic table and indexes automatically. No manual SQL import or public database access is needed. Keep the database URL's supplied connection/security settings; the code does not disable certificate verification. An external database must support the URL/TLS settings you supply.

If the database is unavailable, combat can still run. Reporting shows unavailable and retries with a bounded queue. F8 downloads remain available. A closed/crashed browser can lose unsent samples, so automatic reports are best effort.

## 3. Update itch.io

Upload `FX_Crossroads_Network_Alpha_T4_13_Web.zip` as the browser game. It contains `index.html` at the ZIP root, plus `reports.js` and the Godot runtime. Replace the old browser upload. Reload the game after publishing; close old tabs so every tester runs T4.13. Do not upload the Source ZIP as the playable browser build.

## 4. Run the first test

1. Host a room and choose **Test arena • players only** for a comparison test, or **Gladiator arena • players + enemies** for the original Crossroads Gladiator map.
2. The host controls the arena choice before Start. Joining players see the selected arena. Two or more players are required; each remains able to battle the others.
3. Gladiator begins with four nearby enemies: two archers and two melee creatures. Real server AI moves, fires and deals damage. If fewer than two survive, a periodic check replenishes up to four without replacing surviving enemies. This bounds the test load.
4. Try Soccer, Beekeeper, Sunflower and a melee hero. Include moving targets, wall shots, charged releases, dash/mini movement, and touch input. Check both your own projectiles and the other screen. Local previews never award damage; the server decides hits.
5. Play for at least 30 seconds. The small Reports badge should change to **saved** and show the room code. Batches normally send every 15 seconds; click the badge to request a send. Browser suspension, outages and slow frames can delay this.

## 5. Review all devices together

Open `https://fx-crossroads-network-alpha.onrender.com/reports` in your browser. Sign in with username **teacher** and your `REPORT_ADMIN_PASSWORD`.

Press **Refresh**, select **View match**, and compare the devices' FPS, round-trip latency, local launch delay, server shot receipt delay, correction size and enemy/projectile counts. Press **Download combined match report** and attach that single JSON here for analysis. This private dashboard is not automatically accessible to ChatGPT. A room code alone does not grant database access.

The dashboard uses browser HTTP authentication over HTTPS. To end access on a shared computer, close the private/incognito browser session or clear its saved site authentication. Keep the password private. No public share links are created.

## What changed

- Locally owned shots begin as travelling cosmetic previews in the attack frame. Server confirmation uses the action sequence and shot index to replace the matching preview. Corrections are bounded; authority removal ends the shot. A lost confirmation cannot keep a speculative shot flying indefinitely or resurrect it immediately afterward.
- Shared immediate launch recipes cover 21 ranged attack families across the roster. Charge timers, windups, channels, lobbed attacks and other special mechanics keep their authored timing. Homing/bounce decisions and all damage remain server authoritative. Other players' projectiles keep buffered playback.
- Enemy drawing now uses the same server playback clock as remote projectiles.
- Automatic reporting uses anonymous browser/device and match identifiers, a diagnostic field whitelist, short-lived match upload tickets, bounded queues and async database operations. The database pool is capped at two connections. Reports contain no display names, email addresses, passwords or database credentials.
- The dashboard groups devices by match and exports a single combined file. Reports are removed after 30 days by a periodic cleanup. Save exported evidence you want to keep longer.
- Student accounts and cloud progression saves are NOT implemented in this release. The PostgreSQL database can support separate account/progress tables later, with authentication and server validation added then.
- The mobile summon hit fix, temporary goalie-wall expiry, anchored melee effects and existing movement/dash work remain included. The real-time town/day-night project is separate from this alpha.

## Validation and limits

See `T4_13_VALIDATION.md` in the Source ZIP for the final checks. Automated local/headless tests verify behavior; they do not establish smooth performance on your Chromebook, phone, school Wi-Fi or Render deployment. A new 2–4-device playtest remains the acceptance test. Report batching is intentionally separate from the authority's combat processing; it is not a cure for GPU/browser stalls.

Launch timing starts when the attack request is sent. "Launch shown" records submission of the first projectile draw commands, not physical monitor refresh or the time spent holding/charging a button. Server receipt timing measures when the client receives a snapshot containing its shot. Sample timestamps and match elapsed time are included for comparing batches.

Technical references used:

- https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html
- https://www.gabrielgambetta.com/entity-interpolation.html
- https://node-postgres.com/features/pooling
- https://render.com/docs/postgresql-creating-connecting
- https://render.com/docs/configure-environment-variables
- https://render.com/docs/deploys
