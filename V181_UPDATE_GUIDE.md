# Crossroads v181 — solo and AI parties

Deploy the SERVER update first, then the WEB update. Both use V181-preview, protocol 11 and report schema 3. Keep the existing Render service, GitHub repository, database, DATABASE_URL, REPORT_SIGNING_SECRET and game URLs. No database migration or reset.

1. Extract Crossroads_v181_Server.zip. Upload its CONTENTS to the existing server GitHub repository, replacing matching files. Do not upload the ZIP as the only repository file. Dockerfile.network and project.godot stay at the repository root.
2. Deploy the latest commit on Render. Its /health response should show build V181-preview and ready:true. The new server manifest lists hashes for the packaged files.
3. Replace the itch.io browser upload with Crossroads_v181_Web.zip. Keep the ZIP intact and mark it as the HTML/browser build.
4. Open the game afresh so devices load the new web build. Existing profiles, local progress and database reports are retained.

PLAY OPTIONS
- Gate Defence, Ram’s Descent, Gladiator Arena and Battlegrounds: prominent PLAY SOLO on the device, or Host/Join multiplayer. No server connection is needed for local solo.
- Normal realms and Quest Area (Wayfarer): solo or human co-op; normal realm/quest AI companion seats can be configured too.
- The Between and overcharged realms: solo or existing two-human co-op. AI companions are not supported in those special expeditions. Attunement remains solo. Existing costs and eligibility still apply.
- Locked realms and destinations are greyed out. The Between still requires a Sunfield Expanse or Frostbound Rink clear. Co-op entry remains checked by the authority.

AI ROSTER
Use AI roster to enable seats, choose their hero and (for Arena/Battlegrounds) team, then Apply. Seven selectable kits: Sable Voss (duelist), Brass Bastion (bulwark), Cinder Oracle (caster), Lumen Vale (healer), Thorn Reedwarden (vanguard), Iona Stormglass (ranger), Flint Gearwright (artillery). The four new kits have distinct equipment artwork and attacks. Choose Easy, Medium or Hard.

AI fills player seats: normal co-op allows two total actors; Gate Defence/Descent up to the selected 2/4 seats; Arena up to eight. In online rooms only the host can configure AI. To invite another human into a filled room, remove an AI seat first.

Battlegrounds defaults to 3v3, with 4v4 also selectable. Solo automatically fills both factions. For online games, Fill Battlegrounds AI seats balances the remaining seats around connected humans, using the selected preferred AI kits. Change AI first if you want particular allies or opponents. Your own team determines which AI teams are allies.

AI uses normal health, cooldowns, ability level requirements and CC. It moves, chooses nearby hostile targets, steers around obstacles, reacts to projectiles, and can revive downed PvE teammates. Battlegrounds AI can defend threatened barracks, return for affordable recruits/upgrades, and attack hostile structures; it receives no free troops or money. Existing bounded armies and server room admission limits remain in effect. Healers do not heal the opposing Battlegrounds faction.

Any Arena containing AI is practice: hero damage mastery can progress through the existing practice rules; PvP wins, trophy streaks and competitive unlocks are not awarded for beating bots. Local normal realm and special-expedition saves use their existing progression paths.

PRESERVED
Includes v180.2: compact HUD, bottom item/relic dock, blue XP bar, wide centered health bar, larger cooldown bars, outlined Atelier catalogue/details, and rolling-crown Glimmer Dividend. Crowns remain current 168-hour rewards; old best crowns cannot be equipped.

VALIDATION
70 solo/AI/route checks, 91 Atelier/wallet checks and 41 HUD regression checks passed. Real local socket cases covered all five ordinary multiplayer modes at full human capacity (including eight-player Arena and Battlegrounds), one human with AI in each ordinary mode, and a two-human/two-AI Arena. Browser clicks confirmed offline solo launch with a deliberately unavailable endpoint. A 32-second 3v3 authoritative match with five AI spawned armies, purchased five upgrades and held 60 Hz locally (maximum sampled authority tick approximately 11.5 ms). Hosted Render/school-network behavior still needs the students’ next playtest; this is not a claim of live deployment.
