# v90 release checks

Checked with Godot 4.5.1 and Node's built-in test runner. This is a source release; public accounts have not been changed.

| Check | Result |
|---|---|
| Roster audit | 72 heroes; no errors; four required poses and independent mastery slots |
| v90 features | No failures: mastery gates, UI confirmation, river/bridge, per-realm discovery, portable encounter serialization |
| v90 combat | No failures: three timed jabs, all new skills/mastery dispatch, bounded summons, feather travel, guest attacks resolved by host, movement/snapshot authority |
| v90 routes | No failures: every town service with all upgrades built, bridge/forest, mill, mine approach, guide replay, native scrollbar, Honeyglass defenders and boss connectivity |
| Regression scripts | v89 features/combat, v88 party/solo, v87 menus/profile reset, v86 release/multiplayer, v83 gate, v81 arena and v65 town/food passed |
| Room service | 27 tests passed, including version isolation and three-seat Gate Defence |
| Import | Fresh headless asset import and GDScript compilation completed |
| Visual previews | Town square, garden, mountain/cave, arena/post, eastern bridge, training guide, native catalogues, Honeyglass, hero hall and effects reviewed |

Known scope limits: headless/synthetic multiplayer checks do not replace a real two-device internet match. Previews use desktop software OpenGL; phone Safari orientation/touch and school hardware must be checked after exporting. No Web or Windows binary was exported in this workspace because matching export templates are needed. The Windows build script and CI workflow are updated for v90. Some existing test shutdowns report Godot resource cleanup warnings; the new import/combat checks have no script errors.

Follow DEPLOY_V90.md for the Render service update and fresh itch.io export. Final archive integrity and required file checks run during packaging.
