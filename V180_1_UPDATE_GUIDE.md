# v180.1 — compact combat HUD

Upload Crossroads_v180.1_Web.zip to the existing Crossroads: Realms Beyond itch.io project. Mark it as the browser build and replace the v180 web ZIP. Keep a backup. No server deployment or database changes are needed for this client UI patch; use the existing V180 server. The compatible network/report family remains V180-preview, protocol 11, report schema 3. Existing profiles remain compatible.

Combat changes:
- Top HUD shrinks from 179 to 90 logical pixels. Long keyboard instructions are removed from the persistent combat header; the tutorial and help menus still teach controls.
- CC, Glimmers and banked Waylight Shards appear under the realm/mode title. Health and ability cooldowns stay at the top right.
- Food, three clickable item slots and two relic slots move to the bottom in solo and multiplayer combat. On touch devices the slots use two rows away from the sticks and action buttons. Full item descriptions remain in tooltips.
- A separate blue XP bar sits just above the bottom slots. Town keeps its existing top item row.
- Objective panels and minimaps align beneath the smaller header. Relics are marked off in modes where they do not apply.

Validation: 41 native checks passed, including solo item consumption from the bottom dock, town positioning, and desktop/touch slot visibility and bounds for solo, Gate Defence, Ram Descent, Co-op Realms, Arena and Battlegrounds. Browser render fixtures inspected at 1280x720 and phone landscape 844x390, with no unexpected script errors. The hosted Render server could not be reached from this environment; this patch does not claim a fresh hosted multiplayer play test.
