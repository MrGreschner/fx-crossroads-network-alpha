# Version 19

- Removed the cosmetic rectangle beside heroes in solo and multiplayer; sprite artwork is untouched.
- Frostguard's Crease Wall launches an ice orb. Area damage and the four-second ice barrier occur at the chosen landing spot after the orb arrives.
- Fairway Ranger's Chip Shot launches an arcing projectile, dealing its existing 24 damage in an 80-radius blast on landing.
- Both abilities show an aiming circle, a travelling projectile, a landing marker and an expanding impact effect. Range and cooldown remain bounded; multiplayer damage is handled by the host and respects PvP teams.
- Wick Wisps, Sluice Beetles and Pendulum Moths lob explosive shots at a fixed target position. Move out of the warning ring before impact. These enemies are stronger; several Astral Rift enemies and Tick Acorns also have modest health/damage increases.
- Realm order: Whispering Grove, Ember Quarry, Sunfield, Frostbound Rink, Orbital Breach, Hollow Quarantine, Lantern Marsh, Silverfall Reach, Clockwork Orchard, Astral Rift, Shattered Oath. The portal details explain each realm's intended difficulty.

Export a fresh Web ZIP from this project for itch.io. No Render changes required. New headless tests cover delayed impact, ice barrier placement, enemy shots and dodging, PvP team checks, network snapshots, authority and projectile limits. Existing v13/v14/v17/v18 regressions remain included. Check feel and difficulty with students after uploading; the intended difficulty order is not a measured playtest ranking.
