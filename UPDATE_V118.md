# v118 — Tutorial defeat crash fix

Dying during First Steps returns to town immediately. The old enemy update still tried to write to its now-cleared list, causing an invalid array assignment. Combat now stops when the region changes or a modal opens, including the new defeat/results presentation. Mini-boss stomp and projectile damage use the same transition checks. Enemy dictionaries update directly without redundant indexed write-back.

Regression checks cover lethal tutorial melee, projectile and mini-boss attacks, skipping the tutorial, the following town frames, normal-realm defeat and starting a fresh adventure afterward. v116 defeat-credit and v117 charged-attack checks are also rerun. All 80 heroes and previous features are retained.

## Install

1. Stop the running Godot debugger and close the old project. Do not save an unsaved modified `game.gd` over this update.
2. Extract this ZIP into a new folder. Open that folder's `FX_Crossroads/project.godot`.
3. Run with F5 and test the tutorial, including deliberately dying.
4. Re-export Web and replace the complete itch.io game upload. Rebuild the Windows download if distributing it.
5. No Render files, commands or settings change for this fix.

The screenshot also showed a local indentation error and an unsaved `game.gd` tab. This package provides a clean, parser-checked script; opening the freshly extracted project avoids retaining that local edit. This ZIP contains editable source, not a compiled Web or Windows player.

Validated with Godot 4.5.1. School browser and phone smoke tests are still recommended before advertising.
