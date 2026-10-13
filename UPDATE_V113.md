# v113 — Final mobile and onboarding polish

## Mobile play
Secondary, Special and Dodge are now 120-unit circular controls with distinct colours, circular touch detection and visible scale/brightness feedback while held. They sit beside the right aim stick with space between hit regions. Holding an ability still supports charge/release attacks; movement uses a separate finger. Rotating, opening menus or losing focus releases held actions. Layout remains anchored to viewport edges and rebuilds when its size changes. Existing landscape advice remains for portrait screens.

Design reference: Apple Game Controls, https://developer.apple.com/design/human-interface-guidelines/game-controls — thumb placement, separate stick regions, large hit targets and clear feedback. Actual physical size depends on browser viewport scaling; test on the phones your students use.

## First Steps tutorial
The first nine hero cards show the hero's name and combat roles (Melee, Ranged, Support and/or Summoner) rather than an unlabeled primary attack name. When secondary (level 3), passive (level 5), or special (level 6) unlocks, a persistent pop-up explains the ability and input. Desktop instructions say Right Mouse or Space; touch instructions identify circular buttons. Continue/Close resumes the tutorial; the tutorial's normal menu pause prevents movement or enemy updates during the explanation. Queued milestones show individually. Tutorial exit clears the queue. Pop-ups scale to fit the viewport.

## Mistglass Spire: Enemy Field Guide
Replaces the redundant Twisterspell training shortcut. Select discovered enemies and bosses in a searchable, scrollable list to see portraits, names, base health/damage, speed/detection, authored attack parameters, movement behaviour and where you met them. The same enemy encountered in multiple realms has one card with multiple locations. Unknown enemies stay hidden. Existing encounter discovery and portable profile data are reused; the guide does not grant progress or alter combat. Base values can differ from scaled live combat; scripted boss attacks are identified as variable when no authored number is available.

## Verification
Godot 4.5.1 import and targeted checks: starter roles, circular hit detection, button hold/release, reset, rectangular Interact, simultaneous movement/ability fingers, tutorial secondary/special pop-ups, modal input blocking, discovered-only guide, duplicate merging, authored stats, search and clean closure. v112 combat regressions passed. Rendered and inspected mobile, starter, unlock and guide layouts. ZIP CRC and complete extraction verified. Physical iPhone/Android browsers, live multiplayer and compiled exports were not tested here.

## Publishing
1. Extract this editable project into a fresh folder; open FX_Crossroads/project.godot and allow imports to finish.
2. Export the Web preset again; ZIP its exported files with index.html at the ZIP root and upload that browser build to itch.io. The supplied ZIP is source, not a playable Web export.
3. If offering Windows downloads, run BUILD_WINDOWS.cmd and upload exports/FX_Crossroads_Windows_v113.zip; keep the main-menu download destination pointing to your downloadable itch.io build.
4. No Render file, build command, start command or settings changes are required for v113.
