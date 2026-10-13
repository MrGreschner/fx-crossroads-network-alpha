# v48 — Alderjaw and Tumblebrew

Two free playable heroes bring the roster to 32. All earlier updates remain included.

## Alderjaw — beaver
- Bite: close, directional melee, 28 damage; 90 reach; 0.55s cooldown.
- Tail Slap (level 3): broad forward sweep, 26 damage, knockback, 1.2s stun; 6s cooldown.
- Timber (level 6): an upright tree shakes, then falls over 1.1s into a visibly marked 380-unit lane. On landing: 65 damage and 1.8s stun. Walls clip the fall; enemies can leave the lane. 18s cooldown.
- Alder Armour (level 5): stunning a different surviving foe grants 2% damage reduction for 8s, up to 20%. Re-stunning the same foe refreshes its stack. The active percentage appears beneath Alderjaw. Death and a new run clear stacks.

## Tumblebrew — sentient teapot
- Spout Shot: two curling, teardrop-shaped projectiles, 9 damage each; poison deals 1 damage/s for 4s. 0.85s cooldown.
- Tumble Pour (level 3): three smooth, visibly lifted hops along a 240-unit path over 0.9s. Each landing leaves a 3s poison puddle; direct landing damage is 12, once per foe per cast. Puddles refresh 1 damage/s poison. Walls stop movement; the teapot remains vulnerable. 7s cooldown.
- Bitter Bloom (level 6): an aimed brewing cup fills for 1s, then erupts in a 150-radius burst: 38 damage and 2 damage/s poison for 4s. Walls block damage. 18s cooldown.
- Fresh Pour (level 5): landing on an already poisoned foe restores 2 health, once per different foe, at most 6 health per cast.

Poison refreshes rather than stacks. Friendly players are never poisoned or damaged by these abilities. Host-authoritative combat, movement and snapshots support multiplayer; guests do not simulate extra hits.

## Hero list
Alderjaw immediately precedes Iris Chalkbinder. Tumblebrew immediately follows Nera Lockstep. Garrick Runebearer immediately follows Rune Duelist.

## Validation
Godot 4.5.1 headless checks cover roster/art, directional melee, delayed tree damage, armour refresh/cap/expiry, hopping movement and visual lift, puddles, poison, healing, delayed eruption, death/reset and multiplayer snapshots. Existing hero, school co-op and guard checks were also run. Actual game frames were rendered for visual inspection. Physical phone and live itch.io/network tests require the newly exported build.

## Install
Open this editable project in Godot and export a fresh Web build using the existing presets. Upload that exported Web ZIP to itch.io. No Render service change is required for this update. Use v48 in place of v47.
