# v129 validation

- Godot 4.5.1 project import and script compilation passed.
- 49 focused v129 checks passed: decision presets; one/three attack execution; starter roles; unlock timing/click protection; an actual fatal tutorial hit; killer identity and retry; Rift roster limits, launch, combat, results, no fake encounters or mastery gains; Studio doorway; three live previews; separate spectator chairs, scaling, camera modes and no spectator Descent badge.
- Previous Studio suites: 301 passing assertions across v124–v128. The mobile/tutorial/field-guide v113 regression suite also passed with the new celebration expectation.
- Room-service logic: 36 tests passed, including all three spectator capacities and lobby configuration changes. Two real WebSocket adapter tests passed, including reconnect/identity restoration and eight fighters plus spectator.
- Rendered screenshots inspected: Enemy Lab artwork/decisions/attack previews, starter choices, unlock celebration and instructions, tutorial defeat, Rift selection and battle, southwest Studio, Arena/Descent/Battlegrounds lobbies and Overview/Action views. UI overlaps found during inspection were corrected.
- 1,559 pre-existing official hero/art files compared byte-for-byte with v128: unchanged. Official hero roster remains 80.

Archive CRC and extraction are verified during packaging; all v128 source payloads are retained. This package is editable source. Web/Windows export templates are not installed here, so exported builds and school-device multiplayer remain deployment checks. Test a hosted match on the actual school network after updating Render and exporting.

Rift enemies are practice echoes: base stats and combat roles are preserved, while bespoke realm puzzles and boss phases use bounded sparring patterns. This is disclosed in the builder.
