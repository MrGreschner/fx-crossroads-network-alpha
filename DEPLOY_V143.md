# Deploy v143

1. Extract the editable ZIP into a new folder and open its `project.godot` in Godot 4.5.1. Allow the first asset import to finish.
2. Run the project locally. Check the west campus, locked/unlocked Academy doorway and the five expanded realms.
3. Export **Web** from this project with the matching Godot export templates. Zip the exported Web files with `index.html` at the archive root. Upload that Web export to itch.io as the browser-playable game; the editable project ZIP is not the browser build.
4. Export **Windows Desktop** from this project for the download version. Package the executable with its required exported files, then replace the downloadable itch.io upload. Check the main menu Download Game link still points at your itch page/download location.
5. Use v143 on all multiplayer clients. Export presets and crash diagnostics now identify v143.

**Render:** no room-service files changed from v142. If your deployed service already matches v142, no Render redeploy, build command or environment change is needed for v143. Keep the existing server URL.

Existing player profile format remains in use. Keep a profile backup before replacing a local build. Browser and downloaded applications have separate local storage: use Download Profile / Upload Profile to move an account between them.

Release spot check: host and guest finish a co-op realm, click Replay with party as host, confirm both enter the countdown and remain together. Test one actual school browser and one Windows download; local automated checks cannot establish school graphics-driver stability or real internet latency.
