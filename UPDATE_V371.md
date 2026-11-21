# Crossroads V371 — Realm Champions (first unlock pass)

Clear a champion’s home realm, then visit Challenge Lodge → Hero Challenges.
Defeat that champion in a level-10, first-knockout duel to unlock them permanently.
Free retries, individual tactical briefs, actual champion kits, no Arena hazards,
no equipment, no mastery variants, no PvP rating or damage farming.

Character Hall keeps locked champions visible with the exact next requirement.
Test hero remains available for Training Yard only. Champion selection is checked
in solo play, multiplayer join/selection, and random Arena picks.

Scope: this pass locks the 25 realm champions only. The nine starter heroes and
other heroes remain available until later quest/achievement/event unlock passes.
Existing profiles retain champions with recorded damage or clears at migration.
Past home-realm clears open the corresponding duels. Mastery and cosmetics stay.
Portable profile exports include ownership. Offline ownership follows the existing
portable-profile trust model; it is not a new authenticated anti-cheat ledger.

Clockwork Apiarist is assigned to Clockwork Orchard for this pass, following the
roadmap proposal. Special quests and achievement heroes are for later updates.

Deployment: upload BOTH matching Web and Server_Project builds. The Editable ZIP
is the complete Godot source project. The Server_Project ZIP is also full source,
including artwork and the existing Node/Godot server service, not a patch or PCK.
Extract Server_Project into the GitHub Desktop repository root, replace matching
files, commit and push. Keep the existing Dockerfile.network Render setting,
environment variables, database, and .git directory. No local build script needed.
The Web ZIP is the browser build for the web host, not the server repository.
No contained server or web file exceeds 100,000,000 bytes; Web data uses 32-MiB parts.

Validation: Godot scene/parse checks; all 25 eligibility, loss, persistent victory
and duplicate reward paths; 75 ability dispatches and combat stepping; real lethal
hit victory/defeat; no damage progression farming; server join and selection
ownership checks; actual Godot screen captures. Tested locally with Godot 4.7.2;
Render/Docker's existing Godot 4.5.1 and live hosted multiplayer were not deployed
or exercised here. Student difficulty/kit balance remains a playtest step.
