# Crossroads: Realms Beyond — v198

## Deployment

This cumulative update includes v197's Colour Clash and Crown Chase, v196's Shifting Labyrinth and Lanternfall, and the earlier server updates. Nothing has been deployed automatically.

1. Extract `Crossroads_v198_Server_Update.zip`. Copy the extracted files and folders into the existing GitHub server repository, replacing matching files. Do not upload the ZIP or an extra parent folder. Commit every supplied folder.
2. Deploy that commit on the existing Render service. Preserve the existing database, account/profile data, service URL, cloud-save key and all environment variables. No database migration or new key is required. Deployment restarts current matches.
3. Confirm the server reports `V198-shatterfloor`.
4. Replace the itch.io browser upload with `Crossroads_v198_Web.zip`, marked playable in browser. `index.html` is at the ZIP root.
5. Have everyone refresh their game tabs so client and server versions match.

`Crossroads_v198_Editable.zip` contains the complete Godot 4.5.1 project. Open `Crossroads_Realms_Beyond/project.godot` for editing. The web build reuses the established Godot web runtime and imported assets with a verified rebuilt resource pack.

## Shatterfloor

Select Gladiator Arena, then the Shatterfloor card. Up to eight players, free-for-all or teams, with the existing seven practice AI heroes supported.

- Three decks: Jade, Twilight and Last Chance. They occupy separate vertical spaces in the top-down map; falling drops you to the corresponding point on the next deck. The camera follows your drop. Falling through the final deck eliminates you for the round.
- A stepped-on tile cracks visibly and collapses after 0.85 seconds. There is a brief safe arrival period at each new deck. Tiles remain missing for that round.
- After 22 seconds, outside-in erosion starts cracking rings, with at least 1.5 seconds of warning. Each round has an 85-second maximum.
- Every hero moves at 260 pixels/second. Character appearances remain; normal hero attacks, special abilities, passive simulation, equipment effects and health damage are replaced by the shared survival rules.
- Left click / touch attack: a short-range directional shove. A hit pushes an opponent 64 pixels without health damage. Shoves have a 0.75-second cooldown. Hit targets receive 1.1 seconds of protection from further shoves. Teammates and players on other decks cannot be shoved.
- Right click / Shift / the Hop button: a 0.34-second hop with a 2.5-second cooldown. Movement input chooses the hop direction when present; otherwise it uses your aim. Hopping crosses missing tiles and avoids shoves, but landing on a hole still causes a fall. Normal hero specials are disabled.
- Three rounds, with a four-second break between rounds. Tiles rebuild and contestants return. Placement earns one point plus one for every player who fell earlier; simultaneous falls tie. Team results use summed player placement points. Equal final totals are draws.
- Eliminated players watch a surviving contestant until the next round. The HUD shows deck populations, round time, placement points, hop readiness and control hints. Results show points, final-round points, successful shoves, deck falls and survivor status.

The server owns tile deadlines, hop/shove eligibility, falls, round transitions and scores. The established ordered action pipeline authenticates the actor and rejects duplicate actions. Clients do not decide tile ownership, elimination or score.

## Arena lobby visuals

Ten illustrated map cards now carry clear play-style badges: duels, PvE/PvP, hazards, timing, labyrinth, exploration, territory, keep-away and floor survival. Selecting a card displays a larger preview, a three-step visual rules strip and the mode explanation. Shatterfloor has a layered-floor illustration with cracked tiles and a hop cue. Existing paint and crown previews remain distinct. The card list supports scrolling and host selection rules.

## Verification

- 32 focused Shatterfloor checks: cracks, falls, shared speed, shoves, knockback protection, hops, team rules, placement ties, round resets, outcomes and JSON replication. Seven practice bots completed all three rounds.
- Two local WebSocket rooms with eight clients each: Shatterfloor FFA and teams. Checked round state, hop replication/cooldown, duplicate actions, rejection of normal hero specials, falls, scores and three-round completion.
- The existing 44 Colour Clash/Crown Chase checks passed, along with four eight-client WebSocket rooms for those modes in FFA and teams.
- Existing combat/protocol checks passed. The 271-check focused Battlegrounds suite passed.
- Browser review covered arena cards and rules, Shatterfloor's first and second decks, results, and a smaller landscape viewport. External services were isolated; no live deployment or physical touchscreen was used.

See `validation/v198` for the final verification record and the included `qa/v198_shatterfloor.gd` and `network_tests/v198_shatterfloor.test.mjs` for repeatable checks.

Real-device playtesting remains necessary: school-PC/phone rendering, touch hop/aim, live Render latency, shove feel, tile timing and team balance. Local automated checks do not establish those results.
