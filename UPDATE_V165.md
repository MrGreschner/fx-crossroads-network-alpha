# v165 — town layering and hero search

Town project decorations (flowerbeds, completed upgrades, planned sites) and realm flags are drawn with scenery before the player. The welcome panel is now drawn in screen coordinates after the world, keeping it above planned buildings and stable across camera zoom.

Vampire Pin is retired from the shared item manifest and its definition removed. Leech Charm remains unchanged at 6% life steal. Run loadouts are temporary, so no saved hero, mastery or educational work is removed.

The shared hero grid now lets ordinary key events reach its search field instead of swallowing them. It searches hero names and displayed roster numbers, and clearing the query restores the list. Both character-hall and multiplayer selectors use this grid. Touch browsers use the same real HTML input bridge as Elder chat, configured as a search field; typed changes immediately filter portraits.

Validation: native key-event tests, solo/multiplayer item registry checks, v164 gameplay regression checks, 76 room-service tests, synthetic HTML-input bridge checks, and visual checks at flowerbeds, flags and a planned site behind the welcome panel. Actual mobile browser keyboard testing remains a post-export check.

This release does not change combat balance except retiring Vampire Pin. It does not implement the upcoming dedicated-server multiplayer redesign.
