# Crossroads V299 — First Steps & Descent pressure

First Steps is now the Lantern Glade: layered sandstone training court, ivory guardian roundel, garden ruins, grand gateways, spring backdrop, raised southern stone face, woodland margins and restrained leaf/light accents.32newscenerydesigns,71placements,6materials,6terrainpages. Raised scenery fades near the hero. Original1800x1200playableworld and12treecolliders retained; tutorial waves, equipment, unlocks, skip/return flow and100startinggold remain.

The new Dawnstone Keeper replaces Bramble ONLY in First Steps. A front-facing mossy stone tortoise with a brass lantern,220HP and three telegraphed attacks: close stomp, lantern-spark fan, staggered dawn circles. At distance it uses sparks instead of waiting for a stomp. The first main realm's Bramble remains unchanged.

## Descent fixes

All21boss/midboss definitions audited through actual host combat ticks. A major-boss controller could continually reselect a close-range move, revert its turn index and wait while the player stayed away. It now advances the attack kit and uses a suitable ranged alternative. Generic pending events no longer suspend an independently owned major-boss controller. Wick-Eater sends staggered burning wick segments toward the locked distant target; far breath becomes cinder sparks. Other range fallbacks include quarry boulders, oracle rain, lances and tolling attacks. Major bosses use shorter ready/recovery delays. Midbosses close distance when preparing melee instead of continuously trying to maintain ranged spacing. Boss/midboss projectiles reach distant targets rather than expiring early. Ordinary mob projectile rules remain unchanged.

Base movement speed: midbosses138–174, main bosses150–186, Unquenchable160(previously75–93). Original depth scaling remains. Existing DescentHP/damage and individual phase mechanics retained. Faster movement and functioning attack cadence significantly change difficulty; classroom/human balance testing is still needed.

Each midboss also gains one new warned attack, alongside its original mechanics:

|Depth|Midboss|Added attack|
|---|---|---|
|5|Cragjaw Foreman|Stone Pick: heavy ranged boulder|
|15|The Fungal Bailiff|Spore Fan: five shots and spore cloud|
|25|Coppersting Bailiff|Venom Needles: three-shot fan|
|35|The Rusted Toll|Tolling Notes: three slow homing notes|
|45|The Last Cartographer|Compass Spear: marked bearing and shard|
|55|Root Notary|Root Lances: three staggered ground strikes|
|65|Lantern Collector|Wick Chain: warned tether area and homing spark|
|75|Ossuary Brewer|Ossuary Flasks: three staggered impact circles|
|85|Thornbound Surveyor|Thorn Scatter: five-shot fan|
|95|Coal Archivist|Cinder Comets: three boulders|

New midboss warning state is included in the existing optional enemy snapshot, using protocol11 and authoritative host execution. Existing effect/projectile caps and enemy-death cleanup remain enforced. Enemy bodies remain front-facing; projectiles and attack cues may aim independently.

## Validation and limits

Godot4.6.3: FirstSteps50native checks and50softwareOpenGL checks; Descent2361checks across84actual-host scenarios(21encounters × close/mid/far/movingtarget,55seconds each), plus retained375guardian and81midboss regression checks. Zero assertion failures or script errors. Tests verify active ranged attacks, attack cadence, damage against an idle far target, varied boss styles, each new midboss move, speed increases, bounded hazards, enemy-death cleanup and snapshot/guest authority. A moving player can still dodge. This is not a human full run, remote multiplayer test, browser playtest or classroom hardware benchmark. Existing ObjectDB/three-resource shutdown warnings remain.

Five FirstSteps images are actual solo-scene renders. Eight Descent images are explicitly labelled controlled engine fixtures showing long-range warnings; they are not full human playthroughs. All generated masters/prompts, normalization, before-source, source baselines, tests, logs and packaging tools are retained in tools/release299.

Targetengine4.5.1 remains. Web andServer are incremental from verified V298 packages, not fresh4.5.1exports. The final Web keeps V298's verified streamed-part packaging: no extracted file exceeds200MB. Full game data is retained. ZIP CRC/hashes, exact PCK part reconstruction, source/Web/Server runtime byte equality and source recovery reconstruction are verified. Loader/wrapper checks use a WASMstub; a real browser playthrough remains pending. Nothing has been deployed and no records/database have been reset.

## Restore and upload

Editable source: extract ALL FOUR V278Editableparts, then final cumulative V293RecoveryDelta(libfile_9849168108cc8191a7cd3aa1602a2814), then final V299RecoveryPatch. This patch is cumulative294–299 over EXACT finalV293, including V298 itch packaging. Do not overlay earlier294–298patches afterward. Open Crossroads_Realms_Beyond/project.godot. Patch alone is not standalone. Keep V298 rollback and old base dependencies; working checkpoints are superseded by this final patch.

Update the Render service using the matching V299Server_Update contents, retaining its environment variables/secrets/database/storage. Then upload the ENTIRE V299Web ZIP to the existing itch.io HTMLgame page and mark it playable in browser. ZIP may exceed200MB; the relevant packaging check is each extracted file. Do not upload the recovery patch as the playable game.

## Next queue

The Between → Oldwater Lake → Coastal Voyage → Wayfarer Wilds → Mistglass Rift. Challenge Hall building has received art updates, but its five challenge maps still use assets/lodges/map_*.svg and need a dedicated visual pass. They were not updated in this release. Sovereign Depths V298 retained. SUBVEIL untouched.
