# v65 — A livelier town and automatic food

Includes all v64 content. No heroes or realms removed; 43 playable heroes. Export a new Web build for itch.io. No Render changes required. Everyone playing together should use the same build.

## Town
- Character Hall is a larger stone hall with a pediment, columns, banners, windows and entrance steps. It retains the existing hero selection menu.
- Supply Shop is an open canopy vendor, with shelves, bottles, gear, barrels, a counter and two display tables. Talk to Bartle, the ram standing in front, to buy the usual items.
- Moss's Pond Pantry stands beside the fish pond. Talk to the cook to buy food and read its automatic-use rules. The menu supports touch, scrolling, keyboard selection and refunds.
- Tessa's Healer Shack has medicine crates, masks and a healer NPC, with references to the Quarantine Medic. Defeat returns you to the space in front of this shack as your selected hero, at full health. Multiplayer defeat returns here when you choose Town; in-match arena respawns and teammate revives retain their existing behavior.
- Wayfinder Lodge: Scout Alden helps choose routes by difficulty. Left / Right, or Previous / Next on touch, filters the scrollable list into All, Easy, Medium/Challenging and Hard/Expert. Read the realm details and enter from here.
- Seedhouse: Rowan sells a pear seed for 8 gold. A successful realm/Co-op adventure ripens it. Return to harvest one Antidote Pear into an empty food slot. One crop at a time; failures and training do not ripen it. Food and crops save on the local browser.
- Additional benches, two ram statues, market tables, paths and a scaffolded building with a carpenter make the town look active and expanding. Crowded flags were removed and a tree/flower bed relocated. Building bodies block movement while NPC approaches and routes remain open.

## One food slot for every hero
Food is separate from the three equipment slots. It is automatically used once; you do not need another button. Food and remaining crops persist across hero selection, scene changes and browser reloads. Unused food remains packed after defeat. Consumed food is removed immediately and cannot be refilled by respawning or restarting a match.

| Food | Cost | Automatic effect |
| --- | ---: | --- |
| Berry Bun | 15 gold | After nonlethal damage leaves you at 60% HP or less, restore 30 HP. |
| Hearty Stew | 25 gold | After nonlethal damage leaves you at 35% HP or less, restore 50 HP. |
| Antidote Pear | 18 gold | When poison is applied, remove it immediately. |
| Cleansing Tea | 24 gold | When poison, burn or bleed is applied, remove all of those currently on you. |

Only one provision can be packed. Refund an unused purchased food before replacing it. Food cannot rescue a lethal hit, does not remove stun or slow, and is not consumed in the training yard. Cleanse removes current effects; it does not provide immunity to later applications. The HUD identifies the food and its trigger.

Solo realms and all multiplayer modes use the same rules. Hosts resolve food effects and replicate each player's remaining slot. Guests persist the confirmed result, preventing an already consumed food from returning on scene changes. Food healing is excluded from spell-healing contribution totals. Late initial food registration works; repeated hero packets cannot refill the slot.

## Validation and teaching
Godot tests covered buying with a full three-item pack, occupied-slot rejection, refunds, real food-menu confirmation, automatic healing for all 43 heroes, threshold preservation, cleanse matching, lethal-hit rejection, training preservation, selected-hero healer respawn, crop planting/harvest/save, difficulty filters, and connected walking routes to every town interaction. Host/guest checks cover food transfer, late registration, repeated-packet rejection, snapshots, guest authority, consumption persistence and all four modes. Existing conversion, co-op, school and mirror/element regression checks passed. Town landmarks and food/Seedhouse/Wayfinder touch menus were visually inspected in Godot.

See FOOD_AUTHORING_GUIDE.md for adding provisions and TOWN_EDITOR_GUIDE.md for the new town assets and interaction locations.
