# v110 — Four new heroes and movement polish

## New heroes
All four are unlocked from the start. The numbered roster now contains 79 heroes.

### 76. Hollow Rider — melee/control
A headless suit of armour carrying a pumpkin lantern, from Moonveil's midnight roads.
- Lantern Reaping: 0.12-second wind-up followed by a forward scythe sweep. 25 base damage, 95 reach, 0.65-second cooldown.
- Harvest Hook: pull the closest forward foe up to 70 distance, deal 14 damage and stun for 0.85 seconds. Seven-second cooldown.
- Passive, Lantern Courage: a successful hook grants 12% damage reduction for two seconds.
- Midnight Gallop: ride a spectral horse for five seconds. +30% speed, +6 primary damage and five nearby hoof damage every 0.75 seconds. No invulnerability; 24-second cooldown.
- First mastery, Broad Reaping: wider reach (115) for less damage (19) and slower attacks (0.95 seconds).
- Final mastery, Last Watch: replace the mount with a stationary, targetable spectral horse guardian. 70 HP, 14 melee damage, six-second lifetime.

### 77. Hazel Hex — control/support
A witch from Lantern Marsh with a pointed hat, broom and copper hair.
- Wickchain: a spinning fireball hits one foe for 18 damage and 35% slow for two seconds. A miss or wall impact leaves a four-second poison pool. Pools deal two poison damage per second and slow by 30%; maximum ten per caster.
- Broom Express: fly toward a selected point up to 1100 range on a clear, legal route. Drop up to six bombs, each with a landing warning, ten damage, 0.45-second stun and two burn damage per second for three seconds. Cannot attack or dodge during flight; 16-second cooldown.
- Passive, Ember Infusion: bomb burns last one second longer.
- Neighbourhood Brew: a large cauldron lasts seven seconds. It targets foes within 310 reach with poison splatters every 0.7 seconds. Allied aura within 150 reach grants +5% damage and 8% life-on-hit, capped at six healed HP per hero per second. Auras do not stack; damage-over-time cannot generate healing. 25-second cooldown.
- First mastery, Cold Wick: stronger direct hit (23) and slow (50%), but missed shots leave frost pools without poison.
- Final mastery, Welcoming Brew: cauldron heals nearby allies for three HP every 0.7 seconds instead of shooting splatters; its aura remains.

### 78. Echo Dancer — technical melee
A ribbon-swordsman from the Folded Coast. Position strikes now to catch foes in their delayed echoes.
- Second Step: a forward cut for 22 damage; an echo repeats half the damage at the same place 0.45 seconds later. Remembers the last three strike origins for five seconds.
- Curtain Feint: return to your most recent strike origin within 400 reach on a clear route. The spot you leave bursts for 12 damage within 70 reach. Eight-second cooldown.
- Passive, Lingering Applause: ordinary primary echoes repeat 65% of direct damage instead of 50%.
- Encore: replay up to three remembered strikes in order, spaced 0.3 seconds apart, for 20 damage each. 23-second cooldown.
- First mastery, Long Ribbon: wider, slower, weaker direct cuts (16), but echoes repeat their full damage.
- Final mastery, Dance Company: replace replay damage with up to three fragile melee companions at remembered origins. 24 HP, six damage, six seconds. All can be attacked and killed.

### 79. Little Menace — melee/control
A mouse brawler with shrinking charms and a risky health-trade special.
- Three Knocks: three quick forward punches, eight base damage each. All three must land on the same foe to apply 35% slow for two seconds.
- Pocket Size: half-size for four seconds with +50% speed and a smaller direct projectile hitbox. Can still attack and take damage; area attacks remain dangerous. Eleven-second cooldown.
- Passive, Small Courage: landing all three punches grants 10% damage reduction for 1.5 seconds.
- Heart on the Line: pay 50% maximum health. Enemies within 165 reach receive that raw damage before their defences. The cost bypasses protection, sharing and food, and can defeat the caster. Twenty-six-second cooldown. Practice mode keeps the caster at one HP.
- First mastery, All In: pay 75% maximum health for more damage, but reduce radius to 110.
- Final mastery, Long Mischief: stay small six seconds, but gain only +30% speed.

## Original heroes and UI
- Young Ram and Crossroads Cat now have different walking frames, with alternating feet and arms, plus gentle body motion. Their existing looks and attacks remain.
- Dribble's primary visibly lunges his body into contact and settles back. Removed the separate flying-ball visual; the attack stays close melee with its existing damage/reach.
- Menu moved from the bottom-right into the top row beside Adventures. The three town buttons have separate, aligned spaces.
- New Character Hall cards use concise, accurate ability summaries, with full details on click.
- Added artwork, sequential numbers, lore, role filters, titles, both mastery alternatives and student catalogue entries for the four heroes. Previous profile data and existing hero IDs are retained.

## Safety and performance
Effect arrays, pools and remembered strikes are capped and have finite lifetimes. Damage excludes allies and checks walls. Flight destinations cannot bypass locked progression paths. Host owns damage, cooldowns and status effects; snapshots carry the new visual/combat state. Local broom flight animates between guest snapshots and receives a reliable landing correction. Summoned guardians/companions use the existing targetable-minion registry. Self-sacrifice does not award damage-dealt or hero-kill credit. Returning to town clears the new effects and forms.

## Validation
Godot 4.5.1 headless tests passed for wind-up hits, team protection, hook pull/stun/guard, mounted speed, guardian targeting/death, direct/missed witch shots, pool cap/lifetime, bomb status effects, safe flight landing, aura team checks and healing caps, DoT healing exclusion, healing-only cauldron alternative, triple-jab slow, shrinking size/speed/expiry and attacking while mini, actual projectile hitbox differences, sacrifice damage/self-defeat/arena respawn, delayed echoes/feint, network snapshot round trip, guest authority and flight animation, normal solo firing, town cleanup and top-button spacing. Earlier v107 minion, v108 training and v109 weather/town tests also passed. Rendered and inspected the new heroes, Character Hall and town at 1280 x 720. ZIP CRC and full extraction verified. Live Render multiplayer and compiled Web/Windows exports were not run here.

## Publish
1. Extract this editable ZIP into a fresh folder. Open FX_Crossroads/project.godot and let Godot import the assets.
2. Export the Web preset again. Upload the exported Web ZIP to itch.io, replacing the browser build. The editable source ZIP is not the browser export.
3. For the Windows download, run BUILD_WINDOWS.cmd and upload exports/FX_Crossroads_Windows_v110.zip separately. Keep multiplayer players on the same version.
4. No Render files or settings need changing for this update.
