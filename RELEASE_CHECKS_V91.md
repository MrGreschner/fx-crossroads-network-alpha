# v91 release checks

Godot 4.5.1 checks passed for the new targeting and revival behaviour. String Scissors has a visible delay and damages the aimed crossing rather than nearby targets outside it. Six-Shooter travels, hits the first target and does not pierce. Cindervane stays immobile in ash form, revives at half health after three seconds, follows ordinary defeat on cooldown, becomes eligible again at 120 seconds, and preserves cooldown across combat resets. Host checks cover arena, defence, Descent and co-op; pending state serializes into guest snapshots.

The vertical Character Hall card order and dessert chef identity passed checks. All 72 heroes passed the roster/art audit. v90 combat/features and town route checks passed with these changes, including the east-bank Chimehouse approach and all town upgrades. The room service passed 28 tests, including version-25 isolation. Desktop OpenGL previews checked river continuity, hall cards, cake artwork, crossed strings and rebirth visuals.

This is a source release, not an exported executable. Nothing has been deployed. A real two-device multiplayer match and phone touch/orientation check remain part of deployment verification. Existing headless shutdowns can report resource cleanup warnings; no script or parse errors occurred in these checks. Follow DEPLOY_V91.md for fresh Web/Windows export and room service 25.
