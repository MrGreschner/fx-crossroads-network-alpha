# v89 release checks

Checked using Godot 4.5.1 on Linux and the included Node room service.

| Check | Result |
|---|---|
| v89_features | Zero failures: 67 heroes, stable numbering/order, normal cards, stance expiry, actual equipped mastery replacement, summons, reduction display, gardening/profile state, bots/countdown and host snapshots |
| v89_combat | Zero failures: three kicks, fire/burn ticks, poison payload, companion limits, rush single-hit rules, average movement distance, eight food triggers and authority boundaries |
| v88_party and v88_solo | Zero failures |
| v87_menus and v87_profile_reset | Zero failures |
| v86_release and v86_multiplayer | Zero failures |
| v83_gate and v81_arena | Zero failures |
| v65_town_food (updated fixtures) | Zero failures, including town reachability and all 67 hero food triggers |
| Room service npm test | 26 passed, zero failed; includes actual WebSocket tests, version separation and spectator/recovery cases |
| Native visual preview | Hero cards, seed UI, post office, effects, countdown, lobby and main menu rendered and inspected |

Older arena fixtures were updated for the intentionally increased five-second countdown; town-food fixtures now use current town bounds and actual late-join state. No test is evidence of school-device performance by itself.

Some existing headless test exits report ObjectDB/resource cleanup warnings. These are not runtime script errors, but should not be described as a completely warning-free engine exit. Physical phone touch/orientation, school GPU stability, production Render and cross-device WebRTC remain deployment smoke checks. Nothing has been published automatically.
