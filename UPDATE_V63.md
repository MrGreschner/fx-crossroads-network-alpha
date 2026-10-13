# v63 — Backbeat and Thistlebond

Includes all v62 content. Thistlebond is free and appended as hero 43. Export a fresh Web build for itch.io; no Render changes required.

## Backbeat
- Sound Wave retains 14 base damage and adds a 25% slow for 1.6 seconds.
- Triple Tempo retains three 8-damage pulses and projectile clearing. Hitting the same enemy with all three pulses from one cast adds burn: 3 damage per second for 3 seconds (9 extra base damage).
- Separate casts cannot combine partial hits. Big Bang and Drums of War are unchanged. Existing orange burn and blue slow indicators apply.

## Thistlebond
A hedgehog envoy with a forest cloak and ribbon-wrapped wand. Health 105, speed 240. Original matching pixel portraits, walking and attack poses.

| Ability | Behavior |
| --- | --- |
| Pact Needle | Traveling needle, 21 damage, 450 reach, 0.75-second cooldown. First enemy hit receives a visible four-second knot mark. |
| Gathering Knot | Aim at ground within 300. After a 0.45-second warning, marked enemies within 240 take 24 damage, are pulled up to 110 toward the knot, and slow 35% for two seconds. Walls block the effect. Bosses cannot be pulled. Six-second cooldown. |
| Change of Heart | Convert a visible non-boss enemy within 380. Eight-second lifespan, with earlier death if its health runs out. One converted ally per caster. Keeps the enemy sprite and melee/ranged role; health is remaining enemy health capped at 90. Melee damage 18 or ranged damage 14 once per second. Cooldown 24 seconds. |
| Shared Promise | Level-five passive: converted ally attacks gain four base damage against enemies marked by its owner. |

## Conversion and progression
Conversion resolves the original enemy's normal defeat once, granting its usual XP/gold and clearing its hostile room/wave slot. The temporary ally is a separate body: expiry, replacement and damage death give no second reward, and do not hold doors or waves open. Capturing does not add fictional damage to the player's contribution total. Reviving enemies cannot revive their hostile original after conversion.
Bosses, player heroes and training targets cannot be converted. No eligible enemy means no special cooldown spent. Allies do not attack their owner or cooperative teammates. Hostile projectiles, melee contact, shared attacks and ground hazards can damage the converted body. In PvP it may fight rivals, but cannot capture them. The body has an ally ring, health bar and remaining-time label. The host resolves attacks, damage and expiry; guests receive snapshots.
Converted foes use balanced basic attacks, not their full hostile summoning/healing/boss scripts.

## Validation
Godot checks cover Backbeat's slow, all-three condition, exact burn duration, missed pulses and separate casts; conversion rewards once, zero artificial damage credit, eight-second expiry, early death, boss/training/player rejection, hostile projectile and area damage, enemy revival suppression, ranged ally attacks, traveling marks and delayed gathering; school doorway progression while a converted body remains alive; host casts, snapshot serialization and guest authority. Existing Agent, mirror/element, school, multiplayer, object-combat and ninja/robot/Rook tests were also run. Character Hall and combat visuals were inspected in Godot.
