# Deploy v159

1. Back up your player profile, then extract this editable project ZIP into a fresh folder. Open FX_Crossroads/project.godot in Godot 4.5.1 and let imports finish.
2. Run the game locally. Visit Ripple & Reel on the southeast riverbank; unlock the rod, cast at the pond and river, keep a fish, display it in a tank and feature it on your card.
3. Export **Web** with your existing preset and upload the **exported Web ZIP** to itch.io. This editable source ZIP is not the playable Web upload.
4. Export **Windows Desktop** separately for the downloadable game. Upload the resulting Windows game package to the location used by your Download Game button.
5. Update the Render room-service files to this version and set **FX_GAME_VERSION=159**, then redeploy. The default in room_service/release.mjs is also 159. No new dependencies or fishing room protocol are required; the published version check must match the client exports.
6. Check Options diagnostics reports **v159** in both the itch and Windows editions. The HTML preset's embedded diagnostics now matches web/diagnostics.js.
7. Test a two-device co-op realm with fishing before sharing broadly: one player protects the angler, both players keep their own collections, and enemies should continue moving during the cast. Download and re-upload a profile to verify the rod, favourite and tanks return.

Fish are local profile collections, not shared tank inventories or authoritative competitive scores. Host/guest controller checks passed; a school-network multiplayer soak test remains your final deployment check.
