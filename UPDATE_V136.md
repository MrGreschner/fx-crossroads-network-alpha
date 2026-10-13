# v136 — photography, sound design and creative evidence

## Media and Game Dev
Type `media` in Elder Ram’s chat. Game Dev (`gameDev` → `R4ms!`) receives the same photo tools. The camera panel opens Photo & film tools. Existing four zoom levels and framing arrows remain.

- F8: three-second countdown and clean PNG capture.
- F9: hide/show the camera and photo tool panels.
- F10: toggle a clean gameplay HUD for OBS.
- Optional thirds, centre/symmetry and broadcast-safe guides.
- Full-screen, landscape 16:9, square 1:1 and portrait 4:5 crops.
- Capture excludes the camera controls, gameplay HUD, Media border and guides. Town signs remain scenery.
- Titles and reflections are collected with small thumbnails in My portfolio. The last eight photos are kept, avoiding a growing high-resolution save. Full-size PNGs download separately.
- A written reflection report downloads from the portfolio. Player ZIPs include photography/ thumbnails and reflections; upload restores the portfolio.
- Game Dev/Playtest captures can download PNGs but do not add to the saved portfolio.
- Live multiplayer is never paused for recording. Existing spectator director controls still take priority over the normal player camera.

OBS continues to handle video recording. No recording encoder or streaming service was added to the game.

## Ability Lab Sound tab
Attach an original WAV or MP3 effect exported from FL Studio, or begin with eight built-in example effects. Limit: four seconds and 128 KB per effect. Level is adjustable from −36 to −6 dB; pitch/playback speed from 0.5×–2×. Listen, remove, or replay it with the attack animation.

The effect plays on a released/cast ability in the lab, battle tests and solo custom-hero runtime. The sound uses the normal Master mute. Playback has a four-voice pool, rate limiting and a bounded decoder cache per runtime. Decoded audio is not generated every frame. It embeds in the ability JSON, hero JSON and profile ZIP; files require no external audio path.

Level 3’s source viewer includes actual audio playback code. Audio and composition lesson notes are available in their tool panels. Full realm music replacement remains a teacher-curated project edit: students should submit original FL Studio exports and a placement brief; this update does not automatically replace official music or change official hero audio.

## Additional feature
A captioned photography portfolio makes media work assessable and portable. Students can explain audience, visual hierarchy, composition and revisions, rather than merely collecting images.

No official hero balance, realm rules or room-service changes. Export new Web/Windows builds; no Render redeploy.
