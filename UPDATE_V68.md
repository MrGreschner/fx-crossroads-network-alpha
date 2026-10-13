# v68 — Final mastery abilities and town spacing

Includes every v67 feature and performance fix. Export a fresh Web build for itch.io; no Render changes are required. Download your personal profile before updating a shared computer.

## Town
- Healer Shack is now **Healer House** in signage, interaction hints and Elder dialogue.
- Tessa is a rabbit healer with long ears and a medical coat.
- The Character Hall moves away from the pond, the food stall moves clear of the border trees, and the stadium sits farther south with an entrance path and moved guard stations. Interactions and building collision boxes follow their new locations.
- A ram traveler sits on a cut log beside the forest campfire. Guard patrols now walk around the moved hall.

## Final mastery techniques — all 43 heroes
Each hero has an optional complete alternate attack/spell, on a different button from its first mastery technique. Both can be equipped together, or either turned off freely in town. The original abilities remain available. The Character Hall shows equipped attack descriptions.

**Unlock per hero: 12 successful clears, 6 different realms and 60,000 combat damage.** Training and teacher testing do not earn this progress. Previous genuine progress counts. The alternate does not spend mastery tuning points.

Six new shared attack/animation patterns support the designs: staggered fans, charged piercing lanes, warning sigils, pulsing ally-safe fountains, curved outward/return pincers and sequential linked strikes. Each hero also has its own vector spell emblem. Damage, delays, range, statuses and cooldowns are individually authored; alternatives exchange features such as mobility, instant healing or a wide attack for another play style.

Examples: Living Book trades Paper Cut for returning folded page blades; Young Ram trades Earthshaker for a delayed faultline lane; Bolt Ironcore trades Missile Volley for a charged piercing rail shot; Quarantine Medic trades an instant special heal for a stationary healing/poison garden. See **FINAL_MASTERY_CATALOG.md** for all 43 designs and exact trade-offs.

## Critical milestones
These are based on successful adventure clears with that hero, separate from the hero’s level within a run.

| Clears | Crit chance | Extra damage on a crit | Average damage gain |
|---|---|---|---|
| 3 | 2% | 20% | 0.4% |
| 6 | 4% | 40% | 1.6% |
| 9 | 6% | 60% | 3.6% |

The highest earned tier replaces lower tiers. Applies automatically without spending tuning points; positive hero damage can crit, including repeated attack/status hits. Healing and enemy attacks cannot crit through this system. Successful rolls show a CRIT label. Chance and bonus are bounded in shared combat.

## Saves, multiplayer and teaching
Old profiles migrate with the final alternate unequipped; their previous clears, damage, titles, techniques and tuning remain. Final equip choices round-trip through profile downloads/uploads. Host snapshots include both technique choices and the crit tier; guests render the final ability effects while the host applies damage. Teacher mode unlocks the new options and highest crit tier while retaining the reversible normal-profile backup.

Students should now design a second mastery attack and its readable graphic on a different button. MASTERY_AUTHORING_GUIDE.md documents the full replacement schema, all six new patterns, custom SVG/PNG spell art, damage budgets and wall/status rules. STUDENT_GUIDE.md and ABILITY_CATALOG.md are updated.

## Verification
All-hero final mastery checks passed: unlock gates, different ability slots, original-data preservation, simultaneous techniques, damage, effect expiry, spell art loading, critical tiers, status/heal effects, blocked paths, profile round-trip and host build fields. Existing v66 mastery/profile, v67 combat, v65 town/food and v56 co-op checks also passed. Town and mastery/ability effects were inspected in a rendered Godot preview. Physical phone/browser performance has not been tested here; a live multiplayer session and student balance feedback remain useful after the fresh export.
