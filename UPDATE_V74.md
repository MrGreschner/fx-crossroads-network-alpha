# v74 — North Gate overhaul

North Gate Defence now has a smaller but still expansive, deliberately arranged three-road battlefield, curved lanes, woodland connections, three soldier-producing outposts, a stream bridge, healing springs, fortified staging courtyard, animated torches, patrols and clearer minimap landmarks.

Each reinforcement batch sends two baseline soldiers per lane from the base and one from its outpost, subject to living-unit caps. Allied guard kills share 20% bounty with every player, with fractions retained; small shared XP rewards support progress. Guards remain separated and block enemies and enemy projectiles.

Wave progression, enemy variety, upgrade costs and opponent stats scale for one to four players. Three-player coverage is the design target. Crowded battlefields delay new waves, keeping combat arrays bounded.

Wave 30 features the unique Tollbreaker boss. Its actual defeat and the removal of all remaining wave-30 attackers are required for the existing bastion unlock. Further waves wait at this checkpoint, then endless defence resumes.

Sable Voss is a mobile, returning rival hero with its own primary, delayed slowing secondary, three-point explosive special, evasive movement, kill XP, level-based progression and timed respawning. Its match state and telegraphs are sent to guests. It resets for a new match.

Validation: Godot import; route-clearance and bridge collision checks; reinforcement, spacing, fraction handling, player/guard kill attribution, rival level/respawn/dodge, warning damage, host/guest state serialization and checkpoint unlock tests; lobby and stability regressions; continuous combat simulations and rendered map/boss previews. Actual school-PC, phone and live-network playtesting remain necessary; numerical scaling cannot guarantee equal difficulty for every hero or team.

Re-export Web for itch.io. No Render server changes. BUILD_WINDOWS.cmd builds the v74 Windows package locally; this source ZIP contains no compiled executable. Use the same version on all clients.
