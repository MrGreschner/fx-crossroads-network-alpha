# Version 30 — Patch, hero 21

Frostguard and Dribble primary damage reduced from 31 to 27. Added free object hero Patch, an animated controller, with original idle/walk/attack pixel art and Bit Buddy robot art.

Patch fires a cross of four 14-damage bolts, clears nearby hostile projectiles with an 18-damage expanding pulse, and summons two short-lived 10-damage companions. Its level-five Extra Credits passive extends summon duration from 9 to 11 seconds. Special cooldown is 18 seconds, longer than the companions’ lifetime, preventing sustained summon stacking under normal cooldowns. Companion behavior follows the existing teammate system and works in solo and multiplayer, including PvP rivals. Added shared `cross_shot` base attack for students and automatic configured companion sprite loading in multiplayer.

Checks pass for the 21-hero registry, damage reductions, four-way projectile creation, pulse clearing flag, solo/multiplayer summon counts and passive duration, summon expiry and companion art loading. Physical browser testing remains for the exported build. All version 29 and earlier changes remain. Export this project for itch.io; no Render change is required.
