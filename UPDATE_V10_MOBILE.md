# Version 10: mobile browser controls

All version 9 changes are included. Touch controls appear on phones/tablets,
or when a touchscreen is first used. Desktop mouse and keyboard controls remain.

Use landscape orientation. Left stick moves; drag the right stick to aim and
hold it away from its centre to repeatedly use the primary attack. Release it
to stop. Secondary, Special, Dodge and Interact have separate touch buttons.
You can move, aim and use an ability at the same time. Touch aim also determines
charge direction, beams and placement of area attacks, at the ability's range.

The overlay is shared by solo realms, practice, PvP, Gate Defence, co-op and
Ram Descent. Item buttons use the three inventory slots. Multiplayer Choice A/B
select attack upgrades/mastery. Menu opens multiplayer travel; Continue returns
to town from that panel. Shops and level-up prompts have numbered choice buttons
matching their listed choices. Shops have page buttons and Supplies has Refund.
The hero list supports direct taps, vertical swipes and Up/Down buttons.
The multiplayer lobby uses larger touch targets, with the device keyboard for
name and room code. Controls release when focus is lost or the scene changes.

## Updating itch.io

1. Extract this complete source project and open project.godot in Godot.
2. Export the Web preset as index.html into an empty export folder. Install
   matching Godot Web export templates if prompted. The preset remains single
   threaded and uses the Compatibility renderer.
3. ZIP the contents of the export folder (index.html at the ZIP root).
4. Replace the playable HTML upload on your existing itch.io game page with
   that exported ZIP. The source ZIP itself is for Godot, not the playable upload.
5. Enable mobile-friendly/landscape options in itch.io's embed settings where
   available. Test in landscape on both a phone and a desktop.

## Validation

Godot 4.5.1 headless import and runtime input checks: simultaneous movement,
aim and a third-finger ability; releases; hero swipe/close; menu controls;
touch attack direction in all four multiplayer modes. These checks passed.
Physical iPhone/Android browser performance, visual layout and multiplayer
connections still require device testing after export. This update adds input
support; it does not guarantee every mobile browser/GPU can run the game.
