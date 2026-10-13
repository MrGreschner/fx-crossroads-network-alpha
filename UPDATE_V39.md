# v39 — Brasslock Borough, Nera Lockstep and garden tactics

- Whispering Grove Lantern Moths now fire sinusoidally weaving projectiles with visible curved trails. Forward speed, damage and cooldown remain unchanged. Solo and multiplayer use the same projectile mechanics.
- Brasslock Borough is a new hard realm before Clockwork Orchard: fifteen divided buildings, thirty interior patrols, forty-five hinged doors, tight streets, brick walls, lit windows, shelves, workshop furnishings, drain grates, lanterns and pennants. Movement and attacks collide with masonry and closed doors. Enemy route planning uses the room/door layout.
- Copper Constables launch three shots that can bank off walls twice. Grate Witches warn then erupt a sequence of ground impacts. Both keep their distance in open sight lines.
- The 1,450-HP Lockmaster Regent alternates bankshot fans, four drain eruptions and a warning-marked collision-aware lunge. Solo and co-op clear all rooms before meeting the boss at the southern courthouse. Co-op shares door state and scales boss health; doors do not reset between patrols and boss.
- Hero 26, Nera Lockstep, is a human lantern courier. Corkscrew Key pierces two enemies; Latchline fires a visible chained hook that pulls an enemy; Midnight Express launches a wide ghost tram after a warning. Master Key adds one piercing target. Original four-pose sprites are included for the hero and new enemies.
- Honeyglass Gardens now has ranged blossoms at varied heights and five Amber Hornets among its patrols. Hornets fire weaving honey volleys that briefly slow. It remains an early realm with a modest difficulty increase.
- Four co-op starting spots remain clear of buildings. City collision uses spatial buckets, and world details are camera-culled. No shaders or additional service dependencies are required.
- Student ABILITY_CATALOG.md documents the new styles and examples.

Validation: Godot import/compile; v39 solo/co-op content, door input, every-room reachability, wall bounce, waveform motion, hook/piercing/tram damage and boss patterns; existing v36 hero mechanics and v38 guard combat checks. These are local engine checks, not a physical phone playtest.

Open the project in Godot and export the Web build for itch.io as usual. No Render changes are required.
