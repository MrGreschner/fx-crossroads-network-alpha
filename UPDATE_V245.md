# Crossroads: Realms Beyond — V245

Items, fishing equipment and legendary relic artwork. Based on completed V244; no deployment performed.

## Artwork and behavior

52 adventure-item definitions are covered: 15 regular CC shop items, six legacy/hidden supplies, 14 crafted supplies and 17 Battleground upgrades. All 22 food provisions are covered. Original item designs and motifs gain matte material planes, soft coloured edges and readable details. Existing hero and NPC artwork remains unchanged.

Fishing has ten rod appearances: starter, Deep Sea Rod, and eight existing earned cosmetic styles, with corresponding held-rod bodies. Net, basket and ten hook/bait icons are updated. The held rod fits the original hand and tip exactly; line and bobber anchors, catch odds, timing, bait consumption, gear ownership and unlocks are unchanged. Deep Sea Rod still costs 1,200 Glimmers. Earned cosmetics keep their original levels.

All 21 relics have individual, detailed legendary artwork: carved jade, weathered brass, frostglass, volcanic stone, honeycomb, river-shell and astral crystal. Effects, rolls, ranks, pity, attunement and rewards remain unchanged. Relics remain available through their existing systems; no new relic shop or currency conversion was added.

## Integration

The vendor, food shop, inventory, apothecary paths, Battleground market paths, multiplayer selector, prepared toolbar, fishing dashboard and workshop share the new artwork. Compact artwork/text cards reduce empty vertical space. Inventory equipment rows use the same logical slot mapping as the toolbar, correcting mislabelled equipment when a potion was bought first. The multiplayer selector and popup icons are limited to 24px, keeping its original compact 210×32 layout with the larger artwork. Purchase/refund, use-item callbacks and save formats are unchanged.

127 cached frames use one 2048×1024 RGBA atlas: 8 MiB decoded. No new particles, shaders, gameplay nodes, animated relic effects or texture uploads per frame.

## Install

Back up the current deployment and persistent player data. Install the complete V245 Server Update while preserving the environment, secrets and persistent data, then restart it before installing the complete V245 Web build. Keep the existing HTTP(S), MIME and security-header configuration; hard-refresh clients. Build: `V245-items-and-relics`; application version: `245`; report schema stays `3`. No player-data migration or reset.

The Editable archive contains the complete Godot 4.5.1 project, original/recovered artwork, native SVG sources, reproducible preparation scripts, QA and evidence. Let Godot import resources before opening scenes. V244 remains separately archived as a rollback.
