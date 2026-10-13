# Version 18

- Character Hall Continue now closes using Enter, including the mobile button. Touch release cleanup happens before callbacks; viewport changes reset controls and refresh the town camera.
- Portal realms, town supplies and realm merchant use scrollable lists with a separate preview and confirmation action. Item descriptions are also displayed in multiplayer shops.
- Ricochet is now Dribble; Ice Goaltender is now Frostguard. Hero IDs and saved selections remain compatible.
- Mara: Riposte Guard secondary reflects enemy projectiles during a short guard stance.
- Stormscribe: Thunderfall special deals 55 damage in a large targeted area.
- Crosswind Striker: Team Huddle special heals 6 HP each second for five seconds in a fixed field. Living self/allies only; PvP team rules apply; no revival. Host authority and snapshots keep multiplayer consistent.

Validation: headless Godot import and v13, v14, v17 and v18 checks. The legacy Python content checker predates several existing realms and is not the release validation tool. After export, test hero Continue and landscape/portrait rotation on the physical phone. No Render update is needed.
