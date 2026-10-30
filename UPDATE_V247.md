# Crossroads: Realms Beyond — V247

Based on the complete V246 release. No deployment performed.

Grass and path materials now use shared, world-aligned textures, with sixteen path edge masks. Existing baked town walks and the market yard also receive the new soil material while retaining their original footprints. The main town square has a shaped civic paving court with portal and wishing-well surrounds. The pond, river and marina now share textured water with eight cached ripple phases; original banks, docks and bridges remain.

The main world portal and all three portal-menu routes have more detailed art and looping animation. Realms keeps its teal carved-stone frame; the Between has a fractured violet frame; Overcharge keeps its reinforced gold and amber identity. Sixteen frames each, twelve frames per second, one shared atlas. Locked routes use a muted static frame. Existing portal travel, unlocks, costs and rewards remain unchanged. Texture loading now also runs in release exports; this fixes the debug-only image-loading calls inherited by V246 scenery and crops.

The larger world portal retains its original foot anchor at (900,727). Building art, entrances, collisions, service points, NPC routes, crops, items, relics, saves, economy and server authority remain as V246. The source-preservation report records every modified original method; all changes are rendering, layout or terrain synchronization.

Install the Server Update before the Web package so build stamps match. Use the same server configuration, accounts and persistent data as before. Keep a backup of the V246 deployment and persistent data. The Editable ZIP is the complete Godot project; open project.godot in Godot 4.5.1.
