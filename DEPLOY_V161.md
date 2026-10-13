# Deploy v161 and enable private activity history

## 1. Update the game

Back up your profile. Extract the complete editable ZIP into a fresh folder, open `FX_Crossroads/project.godot` in Godot 4.5.1, and let imports finish. Export Web and upload the **exported Web ZIP** to itch.io. Export Windows Desktop separately and update the downloadable build. Do not upload this editable source ZIP as the browser game.

## 2. Update the Render repository

Replace/update **all files in this project's `room_service` folder** in the GitHub repository used by Render. In particular, the new `analytics.mjs` is required alongside `server.mjs`, `rooms.mjs`, `release.mjs`, `package.json` and `package-lock.json`. Keep the files together in the service's configured root directory.

Build command: `npm ci` (your existing `npm install` also works).
Start command: `npm start`.
Node version: set `NODE_VERSION` to `24.19.0` (tested version); the service requires Node 22.13 or newer for built-in SQLite. No extra npm dependency or database service is required.

## 3. Enable durable storage — a paid Render service is required

Render's free web service cannot attach a persistent disk. Choose a paid instance before enabling durable analytics. In the service's **Disks** settings, attach a disk mounted at `/var/data` (start with 1 GB and monitor usage). Only files under the mount survive redeploys/restarts. Keep one service instance; disk-backed services cannot scale to multiple instances and redeploys cause a short interruption. Schedule deployment outside active classes.

Add these **Render environment variables**:

| Name | Value |
| --- | --- |
| `NODE_VERSION` | `24.19.0` |
| `FX_GAME_VERSION` | `161` |
| `ANALYTICS_DB_FILE` | `/var/data/crossroads-analytics.sqlite` |
| `ANALYTICS_TIMEZONE` | `America/Edmonton` (change if your school uses another timezone) |
| `ANALYTICS_ADMIN_KEY` | Your new private random key, 32+ characters |
| `ANALYTICS_HASH_KEY` | A different private random key, 32+ characters |

Generate each key on your own computer with Node, running this command twice:

```sh
node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"
```

Keep keys private. Put them in Render's environment settings, **not GitHub, game scripts, itch descriptions or student handouts**. Keep `ANALYTICS_HASH_KEY` stable across redeploys so identifiers remain consistent. You can rotate `ANALYTICS_ADMIN_KEY` to revoke dashboard access. Both keys must be at least 24 characters; the suggested generator produces 64.

Save and redeploy. Without the file path and both keys, activity history stays disabled; multiplayer still works. Database configuration errors produce a generic server log and disable analytics. Node startup compatibility still requires the specified runtime.

## 4. View the information

1. Play the updated game normally for at least one minute with anonymous activity sharing enabled in Options.
2. Enable your existing **Game Dev mode** through Elder Ram.
3. Press **backtick (`)** to open the testing desk.
4. Select **Activity dashboard • private trends**.
5. Enter your `ANALYTICS_ADMIN_KEY` in the masked field. This is separate from the Game Dev password.
6. Press **Refresh trends**, then choose 7, 30 or 90 days and refresh as needed.

Reports arrive automatically while clients play; the view refreshes when you request it. Nothing is emailed. Collection begins after the configured backend and v161 clients are live; it cannot reconstruct previous days. Game Dev sessions do not count. Teacher mode alone has no dashboard access. A key is required even if someone extracts the client code, because the server authorizes every dashboard request.

If you see “not configured”, check the disk mount, database path, keys and Node runtime. “Private key rejected” means the entered key does not match Render. Network blocking and opt-outs leave missing counts rather than interrupting play. Never paste a private key into the Elder Ram chat or a public room name.

## 5. Verify and maintain

Check `/release` reports build 161, two-player multiplayer still works, and the dashboard reports a normal play session but not Game Dev testing. Reload the dashboard after a Render redeploy to confirm previous history remains. Keep a downloaded player-profile backup as usual; those files are separate from the server's activity database.

The dashboard holds 90 days of rolling history. For a longer archive, make a database-consistent SQLite backup using SQLite's backup API or `VACUUM INTO`, then securely download it; do not copy only the main SQLite file while WAL writes are active. Render advises database-native backups rather than treating disk snapshots as database recovery. Monitor disk usage. No deployment, paid plan change or private keys have been created automatically.

Official references: https://render.com/docs/disks and https://nodejs.org/download/release/v24.19.0/docs/api/sqlite.html
