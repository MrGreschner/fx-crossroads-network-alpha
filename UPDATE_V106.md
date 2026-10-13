# v106 — Windows download from the main menu

- Added DOWNLOAD GAME • WINDOWS to the main menu, with a clear download/install panel and itch.io link.
- Explained profile transfer, matching multiplayer versions and Windows-only support in the panel.
- Made main-menu panel height follow its content so the extra button does not overlap other controls.
- Updated Windows builder output, GitHub Actions artifact paths and player instructions to v106. Builder removes only its version-specific output folders before exporting, avoiding stale files in new ZIPs.
- All 74 heroes, v105 Game Dev mode and existing gameplay are retained. No room-service protocol changes (28); no Render redeploy needed.

Read WINDOWS_BUILD_GUIDE.md for step-by-step building and itch.io upload instructions. This source ZIP is not a compiled Windows game. The native version avoids the browser WebGL layer; actual Windows multiplayer and hardware stability must be tested on the school PCs.
