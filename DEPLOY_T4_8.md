# Deploy the T4.8 server patch

Apply these files over the existing local fx-crossroads-network-alpha GitHub repository ROOT (the folder containing Dockerfile.network). Keep other project files. Review, commit and push with GitHub Desktop. Render uses the existing Dockerfile.network and settings. Deploy latest commit between test matches, then check /health: ready true, build T4.8, protocol 3. Upload the separate T4.8 Web ZIP to FX Connections Lab on itch.io and refresh all clients.

This update has NOT been deployed by the assistant. The ZIP is a patch against the original T4 server baseline and contains runtime changes from the intervening client revisions as needed by the current arena class. The complete Source ZIP is the full project if your checkout is missing original T4 files. To roll back a failed deployment, redeploy the previous successful Render commit. Keep that checkout/commit available until this passes testing.

See START_HERE_T4_8.md in the full Source ZIP for exact changes, tradeoffs, validation and testing instructions. SERVER_UPDATE_MANIFEST.json lists the patch paths and SHA-256 hashes. No purchase or Render plan change is required by this patch.
