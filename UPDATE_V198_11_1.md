# Crossroads v198.11.1 — clear shop categories

Build V198.11.1-shop-tabs · protocol 11 · Godot 4.5.1.

The Supply Vendor and solo Realm Merchant now show two large, equally sized tabs directly beneath the shop title: Equipment and Consumables. Each has its own icon and slot explanation. A gold outline highlights the selected category; both choices remain visible. Switching resets the list selection and scroll, and shows only the selected category's available stock. The previous dropdown is removed. Purchases, prices, inventory limits and refunds retain their existing behavior.

This is a complete update including v198.11: bottom-right combat ability-info buttons, top-left basket notification beside town weather, basket locations on click, white consumable text, and Dust Marshal's 17-damage primary / three-second reload / own-Hogtie-only True Grit. Long Barrel remains 23 damage / 3.6-second reload. Earlier fishing, pricing, gardening, records and boss-movement fixes are retained.

Validation: 26 shop checks passed in editable source, the rebuilt web PCK and a native rendered run. Checks cover visible categories, icon/size/placement, selected highlight, both shops' filtered lists, selection/scroll reset, purchases, repeated switching, hiding in non-shop menus, and layouts at 390/960/1280/2048 widths. Both native category views were visually reviewed. Archive CRC and changed source/server/web resources match. The prior v198.11 gameplay validation remains included in the editable project.

## Deploy manually

1. Use Crossroads_v198_11_1_Server_Update.zip for the existing Render service first. This complete package includes the previous Dust Marshal changes.
2. Preserve the existing database, accounts, saves, environment variables, signing secrets and keys. No database reset or manual migration is needed.
3. When the server is healthy, replace the itch.io HTML5 upload with Crossroads_v198_11_1_Web.zip and refresh the game.
4. Crossroads_v198_11_1_Editable.zip contains the complete editable project, earlier update notes and validation scripts.

Not deployed automatically. Real-device playtesting remains.
