# Crossroads: Realms Beyond — v198.7

Build `V198.7-hero-field-guide` · protocol 11 · Godot 4.5.1
Based on v198.6; includes all accepted fishing, fish artwork, hero and arena updates.

## Combat ability guide

Four labelled info buttons sit just below the cooldown area: Primary, Secondary, Special and Passive. Each shows its ability name and input hint. Click any button, including a locked ability, to read its description, unlock level and relevant damage/healing/cooldown/reach values. The panel uses the current hero's effective ability definition, including replacement mastery attacks.

The panel is inspection-only: clicking it cannot cast an attack. Escape, its close button, or an outside click dismisses it. Inspecting abilities does **not** pause the fight; movement and enemy simulation continue. A footer makes that clear. Charged attacks cancel while inspecting. The buttons hide for town, menus and modes where the normal hero kit is replaced, such as Shatter Floor. On narrow screens the buttons use two columns, and the bounded detail panel provides scrolling.

## Kage Moonstep

- **Twin Fang:** 15 base damage per cut, two cuts 0.14 seconds apart. Added two sharper katana sweeps with moonlit blade trails, following the hero's displayed position and matching the existing reach.
- **Windwheel:** 26 base outward damage and 18 return damage. An outward hit applies **3 bleed damage per second for 4 seconds**, totalling 12 damage before mitigation. Each target is still hit once per leg. Return hits neither apply nor refresh bleed. The shuriken has refreshed spinning blade graphics and a distinct return tint.
- Existing range, cooldown, passive marks and mastery modifiers remain. Repeated outward bleeds refresh the shared bleed effect rather than adding an unlimited stack.

## Hero artwork and effects

| Hero | Changes |
| --- | --- |
| Fairway Ranger | Replaced pink clothing accents with green and navy. Preserved her golf attire, visor, clubs and accepted silhouette. |
| Mara Dawnblade, the swordswoman pictured | Leather chest guard, darker straps and segmented shoulder pieces replace the soft white jacket appearance. Existing 2.2-second guard remains. |
| Lumen Courier | Small tabard, satchel and brass lantern refinements. New light-dart graphic and a visible lantern inside Relay/Sanctuary fields. Existing ally healing and enemy damage remain. |
| Prism Mage | Pale blue/silver mirror detailing preserves Moonveil's aesthetic. Faceted lance/split bolts, spiral shards and crystalline moonlight blooms replace the simpler cues. Ability timing and damage remain. |
| Echo Dancer | A flowing, asymmetric ribbon-swordsman design fitting the Folded Coast lore. Ribbon sabre trails and translucent dancers distinguish immediate cuts from delayed memories and Encore replays. Existing attack origins, timing and damage remain. |
| Chronicle Keeper | Small brass/hourglass, book and coat details preserve the established design. |
| Hazel Hex | Cleaned up the orange area beneath her chin into a clear neckline and collar; preserved the side hair, hat, broom and spell style. |

All seven artwork updates include six editable 64×64 pixel poses. Kage's existing sprite is preserved. Student-friendly pixel and vector authoring scripts are included in the editable project.

## Validation

- New update suite: **67 checks passed** in the editable source and rebuilt web PCK. Covers Kage's individual cuts, outward/return hits, four bleed ticks, return-only hits, snapshot roundtrip, guide labels/details, accidental cast prevention, hero changes, unlock levels, viewport bounds, all 42 updated pose loads and the actual arena attack path.
- Real rendered UI: mouse clicks open the correct ability, do not cast attacks, and Escape closes only the info card. The panel also stayed bounded on a short landscape viewport.
- All refreshed vector attack cues rendered successfully in Godot/OpenGL.
- Fishing/UI regression: **246 checks passed**.
- Previous v198.4 hero gameplay: **44 checks passed**.
- Original combat/protocol suite: **0 failures**.
- Web PCK resource checksums round-tripped. Fishing catalogue and all fish artwork are byte-for-byte preserved from v198.6. ZIP CRCs and required deployment files verified.

Real-device and live-latency playtesting remains; no fresh eight-client networking run was performed for this update.

## Manual deployment

1. Apply **Crossroads_v198_7_Server_Update.zip** at the root of the existing Render source project. Use the current Dockerfile.network setup and retain the existing service, database connection, accounts, saves, environment variables, passwords and keys. Deploy server first and confirm `/health` reports `V198.7-hero-field-guide`.
2. Upload **Crossroads_v198_7_Web.zip** to the existing itch.io HTML project. Keep the whole archive, including `web/browser`, then refresh the browser/game.
3. Keep **Crossroads_v198_7_Editable.zip** as the full editable Godot project.

The previews show the updated hero poses, an actual rendered combat guide, and a gallery of the refreshed attack cues. No live deployment or database change was performed while preparing these files.
