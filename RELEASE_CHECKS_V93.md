# v93 checks

- Godot 4.5.1 editor import: no script parse errors.
- `tests/v93_menu.gd`: passed, including opaque main page, cached hero/enemy gallery, retained profile actions, title animation, translucent pause, input restoration, separate multiplayer enemy registry, live profile restriction, ridge-tree placement and cave/post access.
- `tests/v87_menus.gd`: passed existing menu, level-up, live simulation and profile-guard regression checks.
- `tests/v90_routes.gd`: passed with all town upgrades enabled, northern entrance, widened postal footprint and new tree positions. Checks were run with an isolated test profile for the route pass.
- Rendered and visually inspected the full main page, western ridge approach and Squirrel Post courtyard with the Compatibility renderer. Local software driver warns that V-Sync switching is unsupported; no rendering script exception was reported.
- Font licenses bundled under assets/fonts/LICENSE.txt.

v92 Battlegrounds source and protocol 26 are retained. This presentation update does not change room-service behavior. No live device multiplayer match, phone touch test, deployment or playable Web/Windows export was performed here. Follow DEPLOY_V93.md and run the real-device release checks before public deployment.
