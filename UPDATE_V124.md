# v124 — Crossroads Studio

- Continue is the first main-menu action, with a gold border. New Game remains green; panels scale to their actual minimum size.
- External Hero Workshop entries are renamed Crossroads Studio. The hub offers Hero Workshop and Ability / Attack Lab.
- A town Studio building opens a separate walkable classroom with Mr. G, a ram teacher.
- Pixel editor: pencil, eraser, fill, picker, hex colours, undo, transparent PNGs, pose copying/mirroring/shifting and design lesson.
- Live walk preview and up to eight attack-animation frames, including animated travelling projectiles.
- 24 reusable ability types including bounded custom programs; 17 passives with scoped aura settings.
- Ability Lab: numeric GUI, editable Crossroads Script, live replay, loop/condition/arithmetic support, CS lesson and saved custom attacks.
- A Start Test tab follows Mastery. Example hero has a genuine custom coded action.
- Character Hall defaults to Official; Custom toggle shows up to 20 local playable creations for solo realms and training. Custom multiplayer is deliberately unavailable pending validated network transfers.
- Player downloads are ZIPs: profile.json, heroes/, abilities/ and Studio draft. Import supports ZIPs and existing JSON profiles, with replacement preview. Studio projects and abilities can be shared individually.
- Official hero JSON and artwork, official roster order and multiplayer server files are unchanged.

See CROSSROADS_STUDIO_GUIDE.md for controls, classroom workflow, limits and deployment. Re-export the Web and Windows editions from this editable project; replace the itch.io uploads. No Render configuration changes are needed.

Validation: Godot functional tests, native project/report transfer callbacks, ZIP code/art round-trips, custom attacks against real training targets, existing touch/tutorial regressions, desktop visual inspection and archive CRC/full extraction. Browser picker/download end-to-end and school-device performance still require testing against the exported build.
