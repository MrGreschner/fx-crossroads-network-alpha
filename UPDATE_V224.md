# Crossroads V224 — fixed opening camera and distant encounter

- The opening now uses a fixed full-scene camera, removing all pan/zoom keyframes and the loader's zoom-through transition. The view is slightly wider than V223's cropped view.
- Portal, Elder Ram, Young Ram and Bramble are 22% smaller and positioned farther up the path. Their route, doorway energy, hit effects and dust use the same depth scale.
- Cat is 7 virtual pixels right and 11 pixels up, sitting farther onto the rock. Fish size, path and behaviour are unchanged.
- The 22.5-second story, animated creek and foliage, correct portal entry order, title reveal and Skip Intro remain. Gameplay hero sizes and mechanics are unchanged.

## Checks
4782 native timing/art/static-camera checks and 966 native/browser matching-state checks passed. Native key frames and the full preview were rendered for visual review. Browser loader/skip checks also pass. No real-device frame-rate claim is made.

## Deployment
Manual server first, then itch.io. No deployment performed. Preserve all account data, database, saves, records, keys and environment variables. No migration/reset is included.
