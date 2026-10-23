# Crossroads: Realms Beyond — V198.38

Build: `V198.38-realms-records-machinery` · Godot 4.5.1 · Protocol 11.

This cumulative release includes the complete V198.37 Learning Academy/Studio/Descent update and the adjustments below. Use these ZIPs instead of V198.37. Nothing has been deployed to Render or itch.io.

## Community records

- New **Ram’s Descent** board: top ten signed-in accounts for solo and top ten for co-op, ranked by highest completed floor. Ranks 1–5 and 6–10 use two columns. Merely entering the next floor does not inflate the result.
- Results are saved on floor completion, including the hero and recorded co-op party. Developer, spectator and practice restrictions remain in effect. Existing known co-op bests migrate from the portable profile when it resyncs. An old combined best can populate solo only when the stored information proves it exceeded that profile’s co-op best.
- Co-op realm times now retain the participating names and heroes with the actual run. The match-start party is retained if a partner leaves during the run. Both portraits and names appear on the community speed records and the realm’s speed cards. Larger recorded parties show every captured member.
- Saved run sources are not inferred from the hero selected later. A slower run cannot replace a faster time’s party. Linked cloud-account names are resolved when the board is read, so a later rename updates the display.
- Older times remain intact. If their partner or hero was never recorded, the UI states that the information is unavailable; it does not invent a partner. New qualifying records capture the full party.
- These remain client-reported community play records, not verified competition results. Descent rankings list each account’s best in each mode; party members may each hold a place.
- The records schema is now 4. Older servers show an update-required notice in the new client. Existing database tables are reused; no table or record reset is required.

## Combat rewards and Battlegrounds

- Ordinary realm and Descent enemies retain the **6–8 CC** base reward added in V198.37. Boss rewards remain 40 CC, and existing item bonuses can add to the base reward. Other game modes retain their own economies; Battlegrounds troop bounties are already higher.
- Fixed Battlegrounds ground rendering covering the obstacle art while collision remained active. Trees/rocks now render after the opaque ground and show their occupied footprint. This applies to both Verdant Front and Iron Rain.
- Client terrain regeneration now follows the received map and lane count, keeping obstacle positions consistent with the authority. Existing army commands and the V198.37 Central Warforge remain available.
- Added a safe guard for progress checks during scene teardown, avoiding detached-node errors when leaving a match.

## Character Hall

The Hero of the Day button now shows the actual hero’s portrait, with the hero’s name in its tooltip. Its detail dialog also uses the shared portrait lookup. Reopening the hall refreshes the daily selection.

## Confluence Foundry performance

Floor tiles, brass rails, windows, columns, seals and drainage details are assembled once into batched geometry. Water ripples use a separate cached mesh with gentle motion; turbines and combat effects still animate. Off-screen machinery is culled using the actual visible area. The dedicated authority skips visual mesh construction entirely. Cached floor rectangles and column positions avoid repeated collision geometry allocations.

In local native testing, the world-drawing function fell from approximately **4.3 ms to 0.18 ms** median. A 10,000-point collision comparison produced identical results with lower CPU cost. These are measurements of the tested functions on this host, not a promise of a particular FPS on school devices. The visible map and its collision layout are preserved.

## Clockwork Orchard

- Moved to **medium** difficulty and its corresponding unlock/menu group.
- Reduced the map from 7,200 × 4,200 to **4,320 × 2,520**, retaining its existing orchard artwork and encounters in a denser layout. The boss has 780 base health for the medium-tier encounter.
- Two gear walls alternate between three passages every 4.8 seconds. Open passages and countdowns are visible. The closing warning asks players to clear the gate; an occupied doorway waits rather than closing on an actor.
- Added **Ratchet Keepers**, mechanical dial-and-spanner enemies that fire spread volleys.
- The Hourglass Hart periodically summons **three Volatile Spark Scarabs**. They pursue and make close attacks, then leave a warned explosive shell when defeated. Move clear before the blast. Active scarabs are capped at three.
- Machinery, held passages and scarab explosions synchronize to co-op clients. Both new enemy types have distinct artwork and appear in the encounter catalogue.

## Brasslock Borough

- Added four Copper Constable patrols for more ricochet pressure.
- Added two **Hinge Conjurers**. They fire bouncing projectiles and can conjure a secret passage through nearby masonry without a line of sight to the player.
- The passage warns before opening, then releases **two fast melee Latch Hounds** on the player’s side. It is a real temporary opening: movement and projectiles can cross the cut wall while it is active.
- Passages remain open for roughly eight seconds after opening and wait if occupied before closing. Doorways and hounds are bounded; local navigation updates only around the changed passage.
- Doorway states synchronize in co-op, and the new creatures appear in the encounter catalogue.

## Cinderheart Citadel

Moved the shop from the arrival/return portal to a safe dry point deeper in the Ember Archive, at approximately **(2540, 5020)**. The arrival portal remains at (480, 5360). Solo and co-op use the same authored merchant marker.

## Manual deployment

1. Keep the existing database and deployment settings. Preserve DATABASE_URL, account/signing/admin keys and all existing saves. No new database or profile is needed.
2. Deploy the **V198.38 Server Update** first, using the existing Render Dockerfile flow. The ZIP root contains `Dockerfile.network`.
3. Wait for the authority to become ready. Check `/health` for `V198.38-realms-records-machinery`, then verify database-backed account/community/classroom status using the existing live configuration.
4. Upload the **V198.38 Web ZIP** to itch.io. Refresh open clients so their map geometry, record fields and server version match.
5. Sign in and press **Resync records** to upload saved known Descent bests. Check a new co-op clear with two accounts, a Battlegrounds client’s collision/art, the gear passages and the moved shop.

Accounts, saves, keys and the production database have not been changed during this development work. Real-device classroom playtesting remains, especially the new timing and enemy balance.
