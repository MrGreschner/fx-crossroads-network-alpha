# v185 — Fishing collection and mastery reminders

## Upload
1. Update the existing GitHub/Render service with the contents of **Crossroads_v185_Server.zip**. This keeps server/report labels and profile validation aligned at **V185-preview**, protocol 11. Keep the existing database, environment variables and signing secret.
2. Upload **Crossroads_v185_Web.zip** as the playable HTML game on the current itch.io page. index.html is at the ZIP root.
3. **Crossroads_v185_Editable.zip** contains the Godot project. Existing v184 gardening, community records and other game systems are included.

Back up the current build and download a profile before replacing the live game. After deployment, open the collection with an existing profile, display a fish in a tank, open its details and try the species filters. Confirm a newly visited active fishing hole appears in Location. Open Mastery with unused points and confirm the highlight clears while the hero selector still lists those points.

## Kept catches
The header is shorter, with gear and weekly-challenge shortcuts sharing one row. The outlined list has more vertical room. Each compact card has fish artwork, rarity-coloured trim, trophy/favourite markings, weight and length, a species-average comparison, an estimated size meter and comparison with that player's best recorded weight for the species.

The size meter estimates where the specimen falls in the existing catch-size model for its species. It is not a comparison with live community player records. Rarity and size remain separate. The fish's original catch metadata and existing trophy rules are preserved.

Fish details, favourite selection, tank selection and release are grouped on the right. Five wide tank buttons become one dropdown. Release still requires confirmation and keeps the species journal/personal best. The selected tab and scroll position are retained after collection actions. Ten-catch pagination is retained for larger bags.

## Species journal
Three combinable filters: discovery status (All, Discovered, Undiscovered), rarity (All plus each rarity), and Location (All plus visited fishing holes). Cards show each discovered fish's picture, catch count, personal records, feeding hours and known waters. Discovered species appear first in All species; undiscovered fish remain unidentified.

Locations are recorded when the player reaches an available shore marker, or completes a catch there. The dawn shoal must be encountered while it is active. Between pools are discovered by pool type when reached in a generated expedition. Newly visited waters travel with the portable profile.

Old profiles restore confirmed locations from kept catches and placed baskets. Old released catches did not store their source in the species journal, so their old locations cannot be reconstructed reliably; revisit those shores to add them. Species discoveries and records remain intact. Game Dev previews can browse all waters; they do not change normal profile exploration progress.

## Mastery reminders
The highlight now means **newly earned usable mastery points**, rather than every unspent point. Opening Mastery acknowledges current points across the hero list and stores that acknowledgement in the portable profile. The hero selector continues to show +points; no points are spent, tuning stays neutral if desired, and the player need not change heroes. A later usable point earned by any hero triggers a fresh reminder.

## Validation
50 Godot native checks passed: migration, visited-water privacy, filter combinations, collection tab retention, tank/favourite actions, save validation, acknowledgement without spending and renewed notification on new points.

Chromium WebGL checks cover rendered collection/journal layouts, the details button, hidden location filters, rarity selection, mastery acknowledgement and a landscape-phone-sized viewport. QA records are fixtures. These checks do not replace a real mobile/device playtest or hosted deployment check. Validation JSON and QA scripts are included with the editable project.
