# Version 24 — enemy damage fix

Enemy warning timers now stop at zero before the attack is resolved. Previously, crossing below zero restarted the warning indefinitely, preventing melee and ranged attacks from firing. This shared multiplayer fix affects Ram Descent and the other multiplayer modes.

Godot tests verify damage against host and guest players at four simulation frame intervals, warning delays, cooldowns, ranged attacks, and intentional invulnerability. All version 23 content remains. Export a fresh Web build for itch.io; no Render update is needed.
