# Alpha lobby update

The Render address is prefilled: wss://fx-crossroads-network-alpha.onrender.com. Empty addresses reset to that default. The default room size is four players.

Hosts can change lobby capacity to 2, 4 or 8 without creating a new room. Only the host can change it, only before the match starts, and not below the existing member count. Guests see the actual room capacity. Connect/start timeouts and early socket closure now display useful messages.

INSTALL: replace alpha source files, commit/push to the alpha GitHub repository, wait for Render redeployment, then export the updated Web client and replace the itch.io lab upload. The new capacity command requires both server and client changes.

Validation: full local networking suite passed; live socket tests cover 2-to-4 capacity change, admitting a third client, rejecting non-host changes and unsafe reductions, and starting all three clients. This does not yet confirm or resolve the reported school-browser joining failure; collect browser Console errors if it repeats.
