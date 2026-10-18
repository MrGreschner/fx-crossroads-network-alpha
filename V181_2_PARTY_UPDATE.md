# v181.2 — visible teams and AI access rules

This update includes v181.1 mastery symbols and independent rain/cloud/mist animation.

## Play options

| Adventure | Solo and human multiplayer | AI allies |
| --- | --- | --- |
| Ram’s Descent | Yes | No |
| Normal realms / Quest Area | Solo or human co-op | No |
| The Between / Overcharged realm | Solo or two human explorers | No |
| Attunement | Solo | No |
| Gladiator Arena | FFA, 2v2, 3v3, or 4v4 | Team matches only; FFA bots are all opponents |
| Battlegrounds | 3v3 or 4v4; solo fills empty seats | Yes |
| Gate Defence | Solo or up to four defending heroes | Yes |

Blue/red lineups show the real character sprites, including every AI. Choose a team with its Join button or by clicking that side of the lineup. Before hosting, moving your hero onto a full AI team exchanges an AI seat to preserve balance. In an online room, full teams reject extra players; the host can move AI using the portrait roster editor. AI slots count towards the normal player limit. FFA bots do not form alliances.

Gate Defence counts all defending heroes, including AI, and maintains the matching number of rival heroes from wave 3. Defeated rival heroes retain their normal respawn delay. The fourth rival is Iona Stormglass, using the existing ranged rival behaviour and a valid road spawn. Regular soldiers and the campaign boss are separate from rival heroes.

## Updating

1. Extract Crossroads_v181.2_Server.zip and upload its CONTENTS to the existing GitHub repository root. Keep existing Render settings and database.
2. Deploy the latest commit on the existing Render service. /health should show V181.2-preview and ready:true.
3. Upload Crossroads_v181.2_Web.zip intact to the existing itch.io page.
4. Use Crossroads_v181.2_Editable.zip for Godot debug.

No database migration, reset, new account, or new server service is needed. Older server builds do not enforce these new team rules; update both server and client. The earlier v181.1 archives are superseded by this combined update.

Validation: local simulation/policy checks, weather/glyph regression, actual WebSocket room tests, and browser review. The next hosted student session still needs to confirm performance on school devices/network.
