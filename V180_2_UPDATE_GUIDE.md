# v180.2 — Gleam Atelier and Crown Dividend

This includes the v180.1 compact combat HUD. Upload Crossroads_v180.2_Web.zip to the existing itch.io game, replacing the previous browser ZIP. No Render deploy or database change is required. It uses the existing V180-preview / protocol 11 / report schema 3 server.

Gleam Atelier:
- Hero preview on the left, full-width catalogue cards in the middle, and a much taller selected-style panel on the right.
- Blue outlined catalogue and gold outlined details, fixed headings with scroll hints, wide contrasting scrollbar handles and touch scrolling.
- Separate scrolling: browsing styles leaves the selected details available. Selecting a new style returns its details to the top. Locked styles can still be inspected.

Combat health and cooldowns:
- Health is now a wide 720-pixel bar centered along the bottom of the 90-pixel top HUD, matching the marked screenshot position. The numeric health value stays readable over the bar.
- Primary, secondary and special cooldown bars increase from 143x9 to 170x16, with larger labels and spacing. Solo and multiplayer use the same renderer.
- Bottom blue XP bar and item dock remain in place. Objective panels and mobile controls keep their existing clear space.

Crown Dividend:
- Every current crown tier gives +0.25% to Glimmers earned. Bronze Spark starts at +0.25%; Celestial I is +2%; Celestial V is +3%; Omnipotent I is +3.25%; Beyonder caps at +4.5%.
- Applies to existing Glimmer earning paths: sales of fish and gathered ingredients, Market daily rewards and eligible realm-clear rewards. It does not add a new source of Glimmers or convert CC into Glimmers.
- No extra combat damage, health or critical power was added. Existing combat crown rules and competition suppression are unchanged.
- Integer fractional carry means small rewards count: at Bronze, 400 base Glimmers earned awards 401 total, whether collected together or across smaller payouts. The bonus itself is not multiplied again.
- Carry persists in profiles. The importer accepts existing four-field wallets and the optional new carry field. Earned/spent/balance accounting stays consistent.
- The current trailing 168-hour crown is checked on earnings. Highest-ever crowns do not activate the bonus. Hiding the crown is visual only. Teacher mode gets no crown dividend.
- Sales confirmations show the actual Glimmers paid, including any whole crown bonus.

Validation: 91 Atelier/wallet/health-layout checks and 41 combat HUD regression checks passed (132 total). Tests cover each crown step, split payouts, save/profile round trips, expiry, hidden crowns, invalid carry, full-wallet atomicity, scroll region sizing and existing combat item use. Browser views and independent wheel scrolling were inspected at desktop and phone landscape sizes. Optional hosted ranking requests were unavailable here; the graceful offline status was checked.
