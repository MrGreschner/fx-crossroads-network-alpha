# Student guide: add automatic food

Food uses one separate slot, shared by every playable hero. Edit `content/foods/catalog.json`; new entries automatically appear at the Pond Food Stand. Keep unique lowercase IDs and give each food a clear description with its trigger and amount.

A healing food:

```json
"trail_apple": {
  "name": "Trail Apple",
  "cost": 15,
  "effect": "heal",
  "amount": 25,
  "threshold": 0.5,
  "colour": "#b5d08a",
  "description": "After nonlethal damage leaves you at 50% HP or less, automatically eat this apple to restore 25 HP. One use."
}
```

A cleansing food uses `"effect": "cleanse"` and a `"statuses"` array, for example `["poison"]` or `["poison", "burn", "bleed"]`. It consumes itself when a matching effect is applied and removes those currently present. It does not prevent future applications.

Use HP thresholds between 0 and 1. Higher healing and broader cleansing should cost more. Food cannot save a hero whose HP has already reached zero. Do not add it to the equipment inventory or `manifest.items`: food is a different slot.

`scripts/provisions.gd` handles the catalogue, purchase/refund, save file, automatic use and Seedhouse crop. `scripts/object_combat.gd` notifies it when a real player gains a status. Solo and multiplayer damage routines check after nonlethal damage. Host snapshots confirm multiplayer food slots; guests never decide damage or consumption. Food healing uses `ability_heal=false`, so it does not inflate the spell-healing scoreboard.

Try these checks after adding a food:
1. Fill all three item slots, then buy food. Items must stay unchanged.
2. Try buying another food while the slot is full. No gold should be spent.
3. Trigger the stated condition once. Only one food should be consumed.
4. Change heroes or return to town. A consumed food must remain gone.
5. Check training, lethal hits and multiplayer snapshots.

Existing tests: `tests/v65_town_food.gd`.
