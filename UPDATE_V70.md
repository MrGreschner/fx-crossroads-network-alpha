# v70 — Player cards and team achievements

- A scrollable Profile page starts with a player card: chosen mastery portrait, title, lifetime damage, realm clears, fully mastered heroes, two arena trophies, and earned realm stickers.
- All 44 heroes offer a portrait when their first mastery technique unlocks. Their final unlock adds a gold star at the portrait’s top-left. Equipping an alternate is not required.
- Expert/Extreme clears earn four unique stickers. Older recorded realm clears also unlock their matching stickers.
- Fixed arena kill-credit logic: checking a victim’s live-target status after their health reached zero prevented knockout scoring. Rival team checks now correctly credit real defeats.
- Regular and random-hero arena records track wins, losses, draws, current/best match win streak, opposing player knockouts, arena monster kills, deaths, and current/best knockout streak within a life.
- Host options: No items/food and Random heroes. Both can be combined. Random mode assigns each player a hero for the match and uses that player’s mastery build for the assigned hero. Stats and trophies are separate from regular mode.
- Fellowship Pavilion, Relay Workshop and Expedition Observatory are new co-op town projects. Their requirements and benefits appear in Town projects.
- Clear every enemy from wave 30 and earlier in Gate Defence to upgrade the town wall automatically. Starting wave 30 does not qualify. Solo or co-op can earn this wall.
- Multiplayer counters use match IDs and cumulative snapshots to prevent duplicate credit. Host owns hero assignments. Leaving or reloading during an active arena ends its match-win streak as a loss.
- Existing profiles remain compatible. Exact realm-only clear counts begin at v70 because older saves combined those clears with Descent/Defence milestones. The older adventure total remains visible below the card. Lifetime damage and prior mastery remain intact.

## Validation

Godot 4.5.1 headless tests cover migration/export validation, portrait unlocks, stars, sticker history, duplicate snapshots/results, separate random records, trophy thresholds, abandoned matches, teacher exclusions, arena knockouts/rescues, guest final-result ordering, item restrictions, and wave-30 clearance. Existing profile restoration, mastery, school and combat replication regressions are also checked. Native rendered previews cover the card, portrait grid, mobile lobby layout and fortified gate. Physical-phone and live multi-device WebRTC tests must be performed after Web export.

## Install

Open this editable project in Godot and export a new Web build for itch.io. All players should refresh to the new build before playing together. No room-service/Render changes are needed. Download your profile before replacing an existing Web upload.
