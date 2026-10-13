# FX Crossroads v122 — Swipe-friendly menus

Drag anywhere in the hero list, realm/wayfinder list, item shop, realm merchant or food list to scroll vertically. Hero and catalog detail panels can also be swiped.

Touches select only on release when no drag occurred. A 12-screen-pixel threshold prevents accidental selection while swiping. Scroll speed accounts for the panel scale, with bounded momentum and a short deceleration after release. Closing a menu or losing focus stops the gesture. Mouse-wheel, keyboard and scrollbar controls remain available.

## Verification
Synthetic touch checks cover scaled hero/realm/item/food lists, tap selection, drag-without-selection, glide, duplicate emulated-mouse suppression, hidden menus, and the actual viewport input route. Earlier v121 companion/combat tests remain part of the regression check. Physical phone/browser feel should be checked after export.

## Deploy
Extract into a fresh folder, open project.godot and re-export Web for itch.io. Re-export Windows if updating that edition. No Render changes are needed. This ZIP contains editable source, not the playable web export.
