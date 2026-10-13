# v149 release checks

- Godot 4.5.1 import/check: no script errors.
- New market/town regression: 17 checks passed. Starter stock, reserve protection, timed start, separate wallets, one-time material payment, free first flower upgrade, cosmetics access.
- Market finance/profile import/ZIP regressions passed (v144).
- Progression/practice/update notice: 37 checks passed (v147).
- Full Studio world/portable creation: 84 checks passed (v146).
- Production Realm Builder: 50 checks passed (v148).
- UI/education/town polish: 50 checks passed (v145).
- Room service: 69 HTTP/WebSocket tests passed.
- Native rendered inspection: Market floor, square, Atelier/arena/post district, Academy road, river construction sites, solo practice HUD.

Checks run in isolated test profiles. Native rendering used the Compatibility renderer and software graphics. Actual school browser/GPU performance and live itch.io/Render connectivity still require a deployment smoke test. No new network protocol or player-profile schema introduced. Source ZIP integrity and fresh-import checks recorded at packaging time.
