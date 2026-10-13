# Version 29 — Gate Defence ranged positioning

Non-boss ranged, burst-ranged, dual-ranged and homing enemies retreat from close players, hold a firing distance of roughly 230–266 units, and separate from nearby enemies. Players within 400 units trigger this positioning. Shooters still advance toward the gate when no living visible player is nearby. Existing close guard engagements, melee units and bosses keep their behavior. Movement uses clear collision-checked retreat positions within the battlefield; defense does not use the small descent navigation grid.

Gate Defence checks pass for archers, ice archers, spore throwers and homing seekers retreating, shooters separating, unopposed gate advance and melee pursuit. Ram Descent movement regression checks also pass. All version 28 features and earlier fixes remain. Export this version instead of v28 for itch.io. No Render changes are needed.
