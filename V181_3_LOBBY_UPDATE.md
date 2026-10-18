# v181.3 — easier party and AI setup

Includes v181.2 rules, solo play, weather animation and mastery glyph fixes.

## Finding an adventure

The left navigation now reads: Normal Realms, The Between, Overcharged Realm, Ram’s Descent, Gladiator Arena, Gate Defence, Battlegrounds, Quest Area / Wayfarer. Locked destinations remain grey. Selecting Normal Realms returns to normal realm selection. Compact navigation keeps every destination visible above the public-room panel on the standard desktop layout.

PUBLIC ROOMS has a permanently visible outlined lower section, a Refresh button, its own scrolling list, and an explanation when no rooms are hosted. Host / Join / Start remain fixed at the bottom.

## Choosing AI

In team Arena and Battlegrounds, each AI selector says ALLY or ENEMY relative to your current side, alongside the blue/red team name and portrait. FFA explicitly labels all AI as opponents.

Gate Defence has two side-by-side panels: YOUR ALLIES / DEFEND THE GATE, and ENEMY RIVALS / ATTACK THE GATE. Enable up to three allies and select their heroes. Choose the enemy rival heroes separately. The active rival count automatically equals all defending human and AI heroes, up to four; extra slots are dimmed. Rival heroes arrive at wave 3 and retain their normal defeat/respawn rules. Each active rival must be a different hero. Inactive duplicate selections are repaired automatically.

All seven AI heroes can be selected as Gate rival champions. They use the existing Gate campaign AI, with kit-based art, names and melee/ranged roles; Lumen supports fellow rivals with healing and Flint fires slower explosive shots. Gate rivals keep the campaign’s level progression and telegraphs. The host owns these choices, which are synchronized to guests and used in both solo and online matches. No AI allies have been enabled in Descent, realms, Between, Overcharge or Wayfarer.

## Installing

1. Extract Crossroads_v181.3_Server.zip; put its CONTENTS into the existing GitHub repository root and deploy the latest commit on the existing Render service.
2. Confirm /health says V181.3-preview and ready:true.
3. Upload Crossroads_v181.3_Web.zip intact to the existing itch.io page.
4. The Editable ZIP is the full Godot debug project.

Keep the existing database and environment settings. No database migration or reset is needed. Update the server as well as the client because enemy-rival selection is synchronized through the server.
