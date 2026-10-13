# v116 — What defeated you?

## Fatal-hit card
The existing defeat results contain a compact LAST DEFEAT section: attacker name, attack name/type and the enemy/hero portrait. PvP includes the player name alongside their hero. Environmental damage uses a clearly labelled hazard card. The multiplayer leaderboard shown while waiting to respawn contains the same card.

The record is created only on an actual defeat, after damage reduction, food, last-stand/rescue checks and rebirth interception in the standard damage routes. A blocked/nonfatal hit does not replace it. Heart Forfeit self-sacrifice is labelled separately. Winning results do not show a defeat card. Each new run/match clears old fatal records; a departed player is removed from match metadata. Live manual leaderboard views hide the card when the local player is alive. Fatal history is not added to permanent profiles.

## Source tracking
Legacy melee and enemy/hero projectiles, shared combat projectiles and sound waves, burn/poison/bleed status ticks, realm warnings/waves, school and tech hits, Descent bosses, forest/world attacks, city eruptions, buried mines, arena hazards, gate projectiles/explosions and Battlegrounds airstrikes carry source information through their damage routes. Projectile/status records retain the source captured when created/applied, so a departed/dead caster need not still exist at impact.

Named abilities are displayed where the damage payload has an authored name; other routes use honest descriptions such as Melee strike, Projectile, Area attack or Ability hit. If a custom damage route has no source metadata, the card explicitly says Unidentified attacker rather than guessing the nearest enemy or inventing a portrait. Authoring a new custom damage effect should pass a source and an attack description to the optional cause parameters. No hit amounts, armour, food, healing, XP, scores or AI behaviour were changed by this feature.

## Networking and performance
The host captures each player's fatal source. Changed defeat records travel with existing reliable player metadata and are removed from frequent realtime states. Full recovery snapshots also contain them. Routine fast states cannot erase a received fatal record. Portraits use existing art resources; no new particle system or image-generation assets are required. Respawn UI rebuilds its small cause row only when the displayed record changes. Both participants should use v116.

## Validation
Godot 4.5.1 tests cover enemy portraits, blocked-hit exclusion, fatal recording, stale-run clearing, retained source after caster removal, environmental labels, PvP player/hero identity, host snapshot data, guest reliable metadata and fast-state preservation, and respawn UI population. v112–v115 regression checks passed. Enemy/hazard results and PvP respawn layouts rendered and inspected. ZIP CRC, full extraction and retention of all v115 payload filenames verified.

Checks use simulated local multiplayer state, not two school computers. Physical phones, compiled Web/Windows exports and live network play were not tested here. This does not establish that browser WebGL context-loss crashes are eliminated.

## Deploy
1. Extract the editable source into a fresh folder and open FX_Crossroads/project.godot.
2. Re-export Web; ZIP exported files with index.html at the root; replace the itch.io browser build.
3. Rebuild/upload the Windows player ZIP if offering the main-menu download. This editable source archive is not the Windows player build.
4. No Render backend file, build/start command or setting changes are needed.
5. Refresh both clients, then check one real two-computer match to confirm the portrait reaches the defeated guest.
