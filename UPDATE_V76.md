# FX Crossroads v76 — the polish update

## First Steps
New profiles see an optional hero picker after the two-second title introduction. Choose from the first nine heroes, then learn in a small, separate clearing: three waves of 3, 4 and 4 enemies, followed by a 190-HP mini-boss. Secondary, passive and special unlock quickly without interrupting the encounter with stat-choice menus. Prompts introduce movement, aiming, dodge and the chosen hero's abilities. Keyboard numbers 1–9 select a hero; touch buttons work too.

Escape or **Skip tutorial** exits to town. Completing or skipping saves that choice; existing adventurers are not forced into the introduction. Replay First Steps through Adventures. Tutorial damage and kills do not earn mastery, record clears or speedrun times. Packed items and food are preserved, and the battle ends with full health in town.

## Adventures
The top-bar **Adventures** button, T key and Adventure Board offer one home for Realms, Quests, Ram Descent, North Gate Defence and Gladiator Arena. Realms have a scrollable difficulty/clear-count list with solo and friends buttons. Existing physical entrances still work. First Steps, the combat visual guide, mastery and Journey cosmetics are accessible from this screen.

## Readable battles
A shared, inexpensive cue renderer supplies outlined danger circles, filling warning arcs, corridor edges/arrows and an **!** marker. School, river/garden/marsh, city, quest golem, folded-coast, North Gate and ordinary boss warnings use it. Enemy lobbed attacks mark their landing area; their visible flight is unchanged. Allied healing zones use a green **+**; enemy healing uses a purple **+** with an amber **!**. Burn, bleed, slow, stun and poison now have small distinct shapes as well as orange/red/blue/white/purple colours. Active attack artwork still keeps its own character.

Warnings are mostly transparent and off-screen cues are culled. Player hits add a faint screen-edge flash; existing hit circles, damage numbers and animations remain. Defeated bosses and victories have short, bounded light bursts.

## Sound
Water, metal, bow/projectile, magic, shield and healing sounds join existing swing/fire/hit sounds, plus a short victory chord. Audio uses the existing six-voice pool; combat cues have a rate limit. **Sound: ON/OFF** stays in the top-right corner in town, battles, menus and multiplayer. It mutes all audio, including Chimehouse, and saves on that device. Browser audio still starts only after an allowed user interaction.

## Results and recognition
Results show the hero, time, damage and mode-appropriate contribution details. Parties see damage, ability healing, revives, defence kills and upgrades per player. Mastery requirements have progress bars; newly unlocked techniques, portraits, titles, badges and available town projects are called out. A solo personal best is highlighted. Sticky buttons open that hero's mastery or return to town; multiplayer also offers Return to party.

Residents occasionally greet nearby players for earned techniques/titles, quests, co-op clears, realm clears and the wave-30 gate achievement. They use saved accomplishments and do not invent them for Teacher Mode. Greetings are short, limited to one at a time and separated by quiet intervals.

## Recoverable interruptions
**Update the Render room service as well as the game; instructions are in MULTIPLAYER_RECOVERY_GUIDE.md.** Game protocol 13 and service version 13 reserve a temporarily disconnected room identity for 45 seconds. The signaling socket retries with bounded backoff; dead direct links can negotiate a replacement. Link heartbeats detect stalled connections. The host pauses active battle simulation while a missing player reconnects, and healthy guests receive the pause too. Resuming sends the existing state and resynchronizes the returning player’s position, without refilling health or replaying match initialization.

After the grace window, a co-op host can continue without an absent guest. An interrupted arena ends without awarding a win, loss or draw. A guest whose host cannot return gets explicit **Restart solo** (non-PvP) and **Back to town** choices. Restart solo begins a new adventure; it does not manufacture a checkpoint. Saved permanent profile progress remains available.

This recovers brief network interruptions while the game process stays alive. It cannot restore a crashed/closed host, migrate host authority, survive a Render service restart with its in-memory room intact, or repair a lost WebGL graphics context. Existing diagnostics and Windows build tools remain included. This archive is editable source, not a precompiled Windows EXE.

## Validation and deployment
Godot headless checks cover all nine tutorial heroes, wave sizes and rapid unlocks, no mastery farming, packed-supply restoration, saved Skip choice, adventure/results menus, touch-control reset, mute, achievements and recovery/expiry outcomes. Existing hero, mastery, mobile, school, town, North Gate, multiplayer and stability regressions are run. Room-service tests cover identity/token rotation, version gates, grace expiry, explicit leave and actual local WebSocket resume/signal routing. Native screenshots are inspected for menu, result and warning layouts.

Live school-network WebRTC, iPhone Safari rotation/audio and a compiled Windows build still need device playtesting. Export a fresh Web build and use matching v76 builds for everyone. Keep player saves/profile filenames unchanged.
