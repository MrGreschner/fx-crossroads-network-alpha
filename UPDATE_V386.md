# V386 — Young Ram leg fragments and Dockside Bait

Removed the two disconnected four-pixel dark fragments at row53 of Young Ram's walking sprites, caused by the V385 upper-body crop seam. Remaining visible art is unchanged byte-for-byte per pixel, including palette, body, legs, size and baseline. The native assembly script now removes these tiny disconnected components when rebuilding. Idle, attacks, gait timing and gameplay speed are unchanged.

Moved Tidecross Dockside Bait from(1983,3825) to(1985,3714), replacing exactly the pine at that location. Neighbouring woodland generation is preserved. Stall, sign, map service marker, interaction target and seller use the new position. Counter collision stays on shore and leaves the dock approach open. Seasonal artwork and shop inventory/prices remain unchanged.

Native Godot4.7.2 captures/checks cover winter/summer, connected walking art, old/new interaction locations, shore access, shop opening and clear dock approach. Source/export/package preservation checks included. No live deployment or physical mobile test. No save/database migration; protocol11 and ownership epoch4 preserved.

Four ZIPs: complete Web, complete full source Server_Project, complete Editable, and Server_Update FROM V385. Extract update contents into existing V385 server repository, replace matching files, commit and push using GitHub Desktop. No deletions or scripts to run. All individual deployed files<100MB and web chunks<=32MiB.
