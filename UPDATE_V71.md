# v71 — Gather your party

## A visual multiplayer lobby

- Four large adventure cards explain each mode and its player count.
- Match settings, the party lineup, invitations and launch buttons have separate clear areas. Buttons support touch input.
- Every joined player appears with their selected hero, alternating its existing walking poses. The host label and your own name identify you. Unknown heroes show a connecting silhouette until their profile arrives; guests receive the whole party lineup from the host.
- In 2v2, everyone starts in the centre. Click/tap Silver on the left or Blue on the right, drag your hero toward that side, or use Left/Right (A/D). Tap the centre to return there. Each side holds two people; the host enforces capacity and requires two players on each side before starting.
- Hero sprites slide into their team positions. Host broadcasts party changes to everyone. Guests cannot alter other players’ teams, and team choices lock during play.
- Start waits for each player’s selected hero/profile and direct connection. Name/code fields and room actions lock appropriately while joined. No-items and random-hero options remain host-controlled.
- Silver/Blue team names and matching floor rings carry into arena gameplay.
- Results display in the party area. Show Party returns to the lineup for changing sides; the host can Start again. Profile-card arena statistics from v70 remain supported.

## Realm mastery stars

Complete a realm **10 times** across any of your heroes to earn a permanent gold star beside it. Solo and co-op successful clears both count. The portal and Wayfinder show the count and milestone; the co-op realm picker includes the star too. Losing, merely entering a realm, Descent/Defence milestones and teacher testing do not earn clears.

Counts are stored per realm in the portable player profile. Prior versions did not record repeat clears separately per realm, so accurate individual counters begin in v71. Existing damage, mastery, titles, badges and total adventure records remain preserved. Profile exports/imports include the new counters.

## Verification

Focused Godot tests cover centre placement, visual side selection, two-player capacity, balanced readiness, hero and roster synchronization, rejection of nonhost lobby packets, locked teams during matches, the nine-to-ten star threshold, cross-hero clears, exclusions, old-profile migration and import validation. Player-card, combat replication, profile restoration and school regressions are also checked. Native rendered previews cover the party lineup, 2v2 teams and starred realm selector. Live WebRTC sessions and physical-phone input should be tested after exporting.

## Deploy

Download a profile backup first. Open the editable project, export a new Web build, and upload the Web ZIP to itch.io. All players should refresh to v71 before joining a room. No changes to the Render room service are needed.
