# Crossroads: Realms Beyond — V251

Build: **V251-descent-depths**. Continues the authoritative V250 Editable, Web and Server Update. Finished locally; nothing deployed.

Cave Descent now uses new warm stone, deep slate/crystal and volcanic floor materials, irregular rock wall trim, stone pillars and textured lava channels. The six pillar positions/radii, navigation grid, arena dimensions, landing points and lava-channel contours remain unchanged. Existing 51 cave character definitions, their sizes and identities remain, with the lava guardian's unkillable teaser attack removed. All V250 marina, shoreline, portraits, cosmetics and prompts and the prior Pippa/Studio fixes remain.

Full guardians every tenth floor gain three added attacks (five crystal lances, expanding echo rings and seeking orbs) and five rotating map-wide dodge patterns: vertical faults, horizontal collapses, a central cross, ceiling falls and an outer-rim collapse. Their health, damage and pace increase with depth. Marked danger gives at least 1.65 seconds to move, with sampled safe regions in every pattern. New warnings stay above darkness. Full bosses pause their ordinary attack sequence during the added area events. Mid-boss attack lists are unchanged.

The floor-100 king gains seven additional attacks: shard lances, echo rings, pursuit orbs, rift mines, seismic cross, shifting crown grid and shard rain. The lava guardian beyond 100 gains six: magma lances, cinder orbs, eruption mines, basalt cross, magma tide and eruption sweep, in addition to its retained firewheel/meteor/quake repertoire. It is now a real, defeatable 21,000 HP solo bonus encounter with party scaling, rather than an invulnerable forced-loss teaser. Beating it ends the run successfully; the existing floor 100 record ceiling remains.

At 20/40/60/80/100 the full boss vanishes exactly 1/2/3/4/5 times at separate health thresholds. Burst damage cannot bypass these phases. Defeat every summoned guard to trigger a 1.5-second return warning. The boss returns with 6% maximum health restored, capped at full HP, and a brief protective ward. Adds are finite (four to seven solo, at most nine with a party), cannot produce CC, and do not allow the floor to advance while their boss is hidden.

Five distinct new enemies:

- **Wickcaller:** stationary lantern ritualist. Eligible ordinary waves from 50, on a three floor schedule; one, or two after 80. Guardian/mid-boss floors keep their own fights. A 2.8-second visible ritual pulls a carried lantern toward it; it catches it and retreats. Any hit, stun, broken sight, leaving its 1,250 px range, or placing the lantern (E) interrupts the channel. The travelling lantern can be intercepted with E. Only one ritual operates at a time, with cooldown and drop protection.
- **Gloamrunner:** fast ferret lantern thief, unlocked 42 and represented frequently after 70. Carries the lantern away along navigable routes, with a slight carrying-speed penalty.
- **Craglobber:** heavy stoneback toad, unlocked 45. Throws a warned boulder with 145 px splash and can knock the carried lantern 185 px away. Drop protection prevents a chain of immediate re-knocks.
- **Riftskulk:** moth-like edge ambusher, unlocked 55. Uses eight perimeter anchors, teleports between them, reveals to aim a warned shot and fades again. It does not orbit the central enemy pack. Fading is camouflage; it remains hittable.
- **Mirebound:** slow cave axolotl, unlocked 48. A 175 px aura slows nearby heroes. It warns before a bounded 620 px hop, leading the target's movement rather than always landing behind them.

Slow ordinary enemies with old bolt/fan/volley attacks now use limited-turn seeking shots, reducing the advantage of leaving a sluggish shooter alive for repeated healing. Their orbs stop tracking after 2.4 seconds and have finite life, allowing dodges. Pippa's decoy can redirect ordinary seeking shots; full-boss shots retain boss immunity.

Ordinary wave scaling begins at 12 instead of 61. At 13/14 this starts a gradual health, damage, movement and attack-frequency ramp. Wave counts remain bounded. Darkness progresses faster (26-depth ramp rather than 34); the placed lamp still gives a wider pool of light. Oil starts draining at 20, from 0.20 fuel/sec up to 0.68 at 100 and 0.75 in the bonus encounter. Four 28-fuel pickups accompany ordinary/boss floors from 20 through 100, and the existing minimum 35 fuel on descent is retained. Lantern placement, interception and fuel management provide counterplay.

Ordinary enemy CC now ranges 3–5 by difficulty and hero/wave/depth level in solo realms, cooperative realms, Descent, Gate Defence and arena NPC kills; Battlegrounds troop rewards use the same range. The CC magnet cannot lift an ordinary kill over 5. Summoned/converted creatures and intermission guards give no CC. Existing 40-CC boss bounties, other boss/team shares, PvP/objective rewards, passive income, quests, trade and shop prices are unchanged.

## Installation and packages

Back up the existing deployment. Apply **Server Update before Web** so their V251 build stamps match. Preserve deployment configuration, accounts and persistent data. No deployment was performed here.

**Web** is the playable browser distribution. **Server Update** contains the matching runtime/server files. **Editable** is the complete Godot 4.5.1 project, original artwork, exact prompts, new asset normalization tooling and QA. **Previews** contains 17 native and 17 Web gameplay captures, the production menu, the contact sheet and artwork board.

To keep Editable below the 512 MiB file limit, V246 historical PNG/GIF review media is relocated to `V251_Previews.zip/Historical_V246/` with exact original paths recorded in `V251_Historical_Media.json`. These are old review screenshots, not game assets. Every original V250 file is preserved across Editable and Previews except the explicit implementation changes. V250 itself remains the independent baseline archive. No original gameplay asset, editable source, save format or original artwork is discarded.

## Verification and limits

**29,342 source checks and 29,342 packaged checks pass: 58,684 total**, across 11 suites. The new 4,350-check suite covers all 101 populated depths, boss versus mid-boss behavior, all 15 minion phases, burst-damage threshold stops, hidden-boss serialization, HP recovery and wards, safe regions in all 5 arena patterns, all 7/6 finale attack additions, lantern interruption/interception/theft/recovery, edge teleporting, predictive hops, bounded homing, boulder splash and lantern displacement, aura slowing, guest authority and CC limits. A maximum 24-enemy mixed late wave runs through 240 host simulation steps with projectile/event caps checked on every step. This is a bounded workload check, not a physical-computer FPS benchmark.

The retained suites cover marina/UI/relative hero size, Fern Double and Studio, actors, town/crops/portals/navigation, items, streets, shops, equipment, healing and the realm finale. The original Descent geometry function is byte-identical apart from controller binding. All 51 existing cave species retain their data except the lava guardian's obsolete teaser attack list. Source, Server Update and Web have byte-identical changed runtime resources. All unrelated V250 exported resources remain byte-identical; compiled remaps for changed scripts are intentionally replaced with their updated source. Changed raw PNG/JSON assets are included in the Editable's future export filters; source originals and prompt/provenance files are excluded from runtime exports.

17 native and 17 Chromium/WebGL2 views cover the entrance, depth 13, deep lighting, low oil, new enemy lineup, ritual and travelling lantern, predictive hop, boulder warning, all 5 boss arena patterns, minion phase, return warning and recovered boss, and the lava fight. The unmodified production opening/main-menu path also passes. Fresh server import and script compilation pass. No script/parse/render errors are accepted. Local live-service fetches are unavailable; those browser fetch warnings are expected. The inherited isolated-test ObjectDB/three-resource shutdown warning remains; the added controller does not add a reference cycle.

No real accounts or scores were used, no live backend/remote multiplayer connection was exercised, and no physical school hardware or student playtest was performed. The requested mechanics and limits are verified; the final classroom difficulty curve still needs real player feedback.

## Artwork, efficiency and reproduction

Eleven original images were generated with the built-in image tool: five enemy pose strips, three stone floor materials, lava-flow material, pillar and wall. The five enemies each have four distinct 80x80 poses in one 320x400 atlas. Exact prompts are in `assets/descent251/prompts.json`; originals and SHA256 provenance are retained beside them. The accepted V207/V208-style board is retained in `tools/marina250_references/accepted_style.png`. No third-party asset pack was added.

Run `python3 tools/prepare_descent251.py REVIEW_OUTPUT` (Pillow/NumPy required) from the Editable project. Without scratch generation paths it reads the retained originals, normalizes alpha, fits four poses to a common per-character scale/baseline, packs the atlas, fits materials/props and rotates the side-wall texture. All runtime assets reproduce byte-identically. The output includes an artwork board. Original art is preserved, so pixel fitting is repeatable without another generation job.

New decoded RGBA texture total is 1,782,784 bytes (about 1.70 MiB). Floor drawing is culled to visible 256 px tiles; walls and lava segment quads are culled too. Animation reuses 20 cached atlas regions. No extra dynamic lights, shader passes, particle systems, physics bodies or network channels are introduced. New events and projectiles use the existing authoritative snapshot path, bounded to 12 events and 36 projectiles. The existing darkness mask and lantern mesh remain cached. Dedicated servers do not load these render textures.

Reproduction/release scripts and the pack writer are in `tools/release251`. They expect baseline250 ZIPs, extracted server250/web250, project251 and out251 alongside the scripts, mirroring the verification workspace. The editable `qa/evidence251` contains compact evidence and integrity data; full screenshots are in Previews.
