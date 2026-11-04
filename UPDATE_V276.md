# Crossroads V276 — clearer movement in four earlier realms

This candidate adds four simple, fixed-view poses to20 distinct enemies across Whispering Grove, Ember Quarry, Honeyglass Gardens and Firstbell Elementary: idle, two visibly different movement frames and attack. Thorn Archer is shared across Grove/Quarry; the Quarry boss retains its separate volcanic identity. Chalkling summons are included.

Grounded enemies use alternate feet/legs and counter-swinging arms. Honey Beetle articulates its six legs. Flying insects use wingbeats; Paper Sprite folds its wings. The Last Bus uses wheel/suspension drawings in its established vehicle view; Recess Ringleader articulates its playground supports. No side/back frame selection, mirroring or whole-body walking bounce. Equipment stays on its established side. Frontal attacks are independent of projectile aiming.

The style follows the user's early Bramble/Archer/Imp reference: coarse pixel clusters, brighter matte midtones, soft coloured edges and restrained detail. Original species, colours, equipment and visible idle height are retained. The80px atlas has binary alpha, no baked shadows, and four distinct nonempty frames per set. Full generated masters, exact prompts, before references and normalization/build scripts are in tools/release276.

All hero artwork, prior V275 animation updates, Frostbound snow/ice classification, environment textures, scenes, content, movement physics, collision, damage, spawning, saves and network protocol remain unchanged. Only new enemy artwork/drawing routes and release/export metadata change.

## Validation and limits

Static validation passed20,087 checks before the hub snapshot update; final report records the current count. Six new/changed GDScript files parse. Source/Web/Server changed runtime bytes and PCK entry hashes are checked. ZIP CRCs and complete source members are verified during packaging. The animated GIF and interactive HTML show the same normalized atlas as the candidate, not live game footage.

Native Godot and browser runtime playtests were NOT run in this workspace because those executables are unavailable. This is a saved-source candidate, not a fully playtested release. V274 remains the last previously runtime-validated release; V275 is the complete candidate baseline. Nothing has been deployed or deleted.

## Restore and run

For complete editable source, extract BOTH V276 Editable Part1 and Part2 ZIPs into the SAME parent. Open Crossroads_Realms_Beyond/project.godot in Godot4.5.1 and allow imports. These parts are standalone and do not require earlier release archives.

The smaller RecoveryDelta/Working_Recovery is a PATCH over BOTH V275 Editable parts. Apply after extracting the V275 parts; it cannot replace them. It includes the changed project files, new originals and recovery notes. Do not remove V275 dependencies while relying on this delta.

Run local QA after import:
`godot --headless --path Crossroads_Realms_Beyond --script res://qa/v276_motion_check.gd`
Also run qa/v275_motion_check.gd for retained animation/surface routes. Then play all four realms in solo and co-op: walking/stopping/attacking, wings at idle/movement, both Grove/Quarry bosses, bus and Ringleader, Chalkling summon. Check visuals at actual gameplay size against scenery and verify attack timing/projectiles. Native parsing/import and runtime playtests remain required before production use.

The Web ZIP is an incremental candidate built from verified V275 Web bytes, with changed script remaps removed and new raw atlas included. It preserves the existing engine binary and autoload setup. The Server Update ZIP follows the existing source-server workflow; preserve deployment secrets and use the project's established server-before-Web process only after testing. Nothing was published.

## Recovery safeguards

The live DEVELOPMENT_RECOVERY_HUB.md, libfile_bab654b363c4819198a9eb0d0b09ff78, owns the successful-save registry. Read its latest version at resumption; a chat claim or source snapshot is not proof a package was saved. Protect V276 complete source plus V275 rollback, all still-required older dependencies, all handoffs/style/prompt notes/original art, and active SUBVEIL Site/source/latest Windows package. Never delete automatically. Continue compact milestone checkpoints before long generation/export work.
