# Deploy v162

1. Download your player profile as a backup. Extract the complete editable v162 ZIP into a fresh folder and open `FX_Crossroads/project.godot` in Godot 4.5.1. Let imports finish.
2. Export **Web** with the existing preset and upload the exported Web ZIP to itch.io. The editable project ZIP is not the browser-game upload.
3. Export **Windows Desktop** separately and replace your downloadable game package.
4. Update your Render repository with the files from this project's `room_service` folder. Set **FX_GAME_VERSION=162** and redeploy. Keep `npm ci` (or existing `npm install`) for Build and `npm start` for Start. Node 24.19.0 remains the tested runtime. No new dependency or multiplayer protocol change was added in this update.
5. If you already configured the v161 private analytics dashboard, keep the persistent disk, `ANALYTICS_DB_FILE`, timezone and both private keys unchanged. If you have not configured it yet, follow `DEPLOY_V161.md` for disk/key setup, using **162** for `FX_GAME_VERSION` instead of 161. Analytics setup is optional for ordinary gameplay; unconfigured analytics does not stop multiplayer.
6. Check Options diagnostics reports **v162** on itch and Windows. Confirm the main menu calls its daily objective **Daily Mission** and Challenge Lodge keeps its own trials.
7. Test Moonveil’s southern canal alone and with a friend. Obtain the rod from Marina at Ripple & Reel first. North Gate's spot is on the south riverbank west of the main bridge; Descent's new spring appears on floor 38 only. Floor 56 still has its original spring. Combat remains live while fishing.
8. Keep/release a new species, check its largest-catch record, aquarium tank/profile-card display, then download/upload a profile to confirm the collection returns.

No deployment was performed automatically. Existing player progress and daily-mission rewards retain their current data keys; a reset is not needed.
