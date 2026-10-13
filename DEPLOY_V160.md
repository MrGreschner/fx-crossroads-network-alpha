# Deploy v160

1. Download your current player profile as a backup. Extract this editable source ZIP into a fresh folder and open `FX_Crossroads/project.godot` in Godot 4.5.1. Let imports finish.
2. Test a pond/river cast: some casts have no bite; hook during the three gold flashes. Keep/release, check size comparison, and view Weekly activities. Visit both redesigned lodges and the apple tree.
3. Export **Web** using the existing preset. Upload the **exported Web ZIP** to itch.io, not this editable project ZIP.
4. Export **Windows Desktop** separately and replace the downloadable package used by Download Game.
5. In Render, update the room service from this project's `room_service` folder, set **FX_GAME_VERSION=160**, and redeploy. Build remains `npm install` (or your existing `npm ci`); Start remains `npm start`. No new dependencies are required. The default release build and embedded Web diagnostics are now 160.
6. Check Options diagnostics reports **v160** on itch and the Windows build. Test two human players in the arena, verify weekly cosmetics appear to the other player, and test an AI match awards no arena reward.
7. Test two-device co-op fishing: combat continues, a missed bite escapes, and each player keeps their own collection. Back up and upload a profile to check fish records, selected cosmetic, weekly progress and tree cooldown return.

Weekly rewards and fish records use local portable profiles and the local device calendar. They are not server-verified competitive rankings. No deployment was performed automatically.
