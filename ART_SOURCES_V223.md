# V223 animated opening film

Built-in image generation produced the empty town-and-creek stage, separate foreground tree boughs, cinematic cat grooming/reaction poses, directional Bramble run/recoil poses, and Young Ram watch/run/headbutt poses. Prompts are preserved in tools/cinematic223_prompts.json. Original generated PNGs and normalized frames are in assets/cinematic223. These are cinematic-only: hero and enemy gameplay sprites are unchanged.

The film is real-time 2D animation: independent foliage motion, a water-only distortion shader/current streaks, camera motion, sprite poses, impact/dust/splash effects and a masked portal. The MP4 is a captured preview, not a mandatory game download.

content/intro223.json is the shared beat specification. scripts/intro_story223.gd and web/browser/cinematic223.js implement equivalent pure state models, verified against matching timed samples. Rendering layers place the whole stone portal behind actors; entering actors shrink and fade into its centre and never travel beyond it. Portal activation finishes before Bramble can appear, and Bramble's retreat completes before Young Ram follows.

Browser rendering is bounded at 30 fps and reuses cached image/mask canvases. After completion or Skip Intro, movie images and canvas backing stores are released. Native scene textures are owned by the short-lived CanvasLayer. Gameplay hero art, camera, stats, saves, curriculum and account systems are unchanged.

## V224 composition adjustment
The camera is now fixed to the full scene (no pan or zoom). The portal encounter uses a uniform 0.78 depth scale with a higher path anchor. The cat moved slightly onto the rock; fish placement and behaviour remain unchanged. No generated artwork was changed.
