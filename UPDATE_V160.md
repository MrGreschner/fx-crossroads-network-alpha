# v160 — unpredictable fishing, lodge redesigns and weekly rewards

## Fishing
- Each 8–14-second cast has a 70% bite chance. Its bite time is random, from 0.6 seconds after casting to just before the wait ends. A quiet cast ends with a no-nibble message; the wait meter never promises a catch.
- A bite dips the float and flashes the indicator three times across a 2.4-second reaction window. Press F or tap Hook. Missing the window loses the fish. Walking, taking damage or opening another menu cancels the cast; realm combat remains live.
- Every landed catch shows the species' previous largest weight/length and a new-weight-record comparison. Both keeping and releasing commit discoveries and personal records. Collections survive profile backup/upload.

## Town
- Gatherers’ Lodge is now a timber lodge with a shingled roof, drying herbs, woven baskets and mushroom crates. Removed its obsolete duplicate path label.
- Knock at the apple tree to its west with E (or touch Interact). With an empty food slot, each attempt has a 20% chance to pack a Lodge Apple. Rest the tree for five minutes between attempts, including unsuccessful ones; this cooldown survives reopening the game.
- The free apple restores 20 HP once, automatically after damage leaves you alive at 60% HP or less. It uses the existing food slot, cannot revive and has no refund value.
- Challenge Lodge has a much wider three-section hall, central trophy crest, side training wings and standards. Its collision footprint and reserved landscaping lot match the expanded building, with a small setback to clear the north fence and market yard.

## Eight new selectable weekly cosmetics
| Reward | Earn during the current week |
|---|---|
| Moonlit Minnow | Catch this week's named species at or above its target weight; keep or release it |
| Merchant's Fortune | Finish a profitable timed market day with at least one sale |
| Duelist's Pennant | Finish one human PvP arena match |
| Silver Crossblades | Earn three player KOs in the arena |
| Champion's Diadem | Win two human PvP arena matches |
| Deepwell Crystal | Clear Descent floor 10 or deeper |
| Trialfire Laurel | Complete two lodge trials |
| Bastion Lantern | Clear Gate Defence wave 10 or higher |

Fishing rotates through eight common/uncommon species and suggested pond, river or quest waters; the size targets do not require trophy-size fish. Unlocks last until Sunday 00:00 in the device's local calendar. Every week starts fresh. Equip one at the cosmetic pavilion or Profile → Cosmetics. Weekly activities is also available in Adventures, the Challenge Lodge and the fishing journal. The board shows animated rewards and progress gauges. The cosmetic picker now scrolls vertically, including touch dragging, with its Done button always visible.

Game Dev, Playtest, continued practice and arena matches containing AI bots do not earn weekly activity progress. Existing best-floor records do not automatically award a new week: new clears are required. Repeated arena/stat snapshots and result callbacks cannot multiply progress. Effects are visible through the existing multiplayer cosmetic payload and do not change combat statistics.

## Verification
Godot import/parsing, solo fishing, host/guest fishing-controller checks, weekly expiry and portable profile checks, timed-market reward, arena snapshot deduplication, apple cooldown/food behavior and lodge access checks passed. Native Godot screenshots reviewed for both buildings, catch comparison, weekly board and cosmetic selection. Room-service tests run before packaging. Perform the two-device school-network check after exporting; controller tests are not a real network soak test.
