# Version 26 — Ram Descent ranged positioning

Thorn Archers, Ice Archers and Spore Throwers now retreat from close players, keep roughly 230–266 units of firing distance, and spread away from nearby enemies. They approach if out of firing range and use navigation when rocks block sight. Retreat candidates avoid rocks and dungeon boundaries. Melee units and other ranged archetypes keep their existing movement. Their speed and attack damage are unchanged, so players can still chase and corner them. Host simulation controls movement for all players.

Checks cover all three retreating types, opening distance, separating adjacent shooters, melee pursuit, arena bounds and choosing a clear retreat beside a rock. Enemy damage regression checks also pass. All version 25 changes remain. Export a fresh Web build for itch.io; no Render update is required.
