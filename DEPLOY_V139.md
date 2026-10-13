# Deploy v139 — update Render AND itch

1. Back up the current project and player profiles. Extract this full ZIP into a new folder; open FX_Crossroads/project.godot in Godot 4.5.1 and let imports finish.
2. Replace **rooms.mjs**, **server.mjs** and **package.json** in your existing GitHub room-service repository using **room_service/** from this ZIP. Commit and let Render auto-deploy, or Manual Deploy → Deploy latest commit. No new service or dependencies are needed.
3. Keep **Build: npm install** and **Start: node server.mjs** (or your existing npm start). Keep the working WebSocket URL and PORT handling. Node 22+ stays required.
4. Once Render is Live, export Web into an empty folder using matching Godot templates. ZIP the exported files with index.html at the ZIP root and replace itch's browser-playable upload. Do not upload this source ZIP as browser-playable.
5. Re-export Windows and replace the downloadable game ZIP too. This environment has no export templates, so playable exports must be built in your Godot installation.

New game clients use multiplayer protocol 32 and require the custom_heroes service capability. Older clients keep their existing protocol rooms; students must refresh onto v139 to join each other. Studio Partner Up retains v138's protocol and two-pencil editing.

## Two-computer release check
- OFF: official heroes join; customs receive an explanation.
- Public + CUSTOM HEROES ON: a Forced Balance build joins; an experimental one cannot.
- Private + CUSTOM HEROES ON: an experimental hero joins by code, artwork arrives, and Start waits until ready.
- Attack opposing heroes and custom minions. Check the cyan/violet badges and both clients' visuals.
- Try all game modes with a custom caster/healer/summoner, plus a rematch and late join. Test on the actual school browsers/network; headless validation cannot establish school GPU/network performance.
- Compare official/custom heroes. Use teacher / fx97 and try Quick test.
- Collect coal, complete an assay, download a player profile and import it on a second machine.
- Keep student profile backups before leaving shared computers.
