# Crossroads V343 multiplayer authority

Extract the V343 authority pack from the accompanying V343 Web ZIP:

    python3 server_pack.py Crossroads_v343_Web.zip Crossroads_v343_Server.pck

The extractor verifies every pack section and the complete resulting PCK.
Replace the game pack in the existing Render deployment. Keep the same Godot
runtime, service configuration and network starting scene. If your deployed
pack has a fixed filename, use that filename for the replacement.

    godot --headless --main-pack Crossroads_v343_Server.pck res://network/server.tscn

Deploy the matching V343 web client. V343 also includes the V342 changes
to Pippa and event hero record eligibility.
