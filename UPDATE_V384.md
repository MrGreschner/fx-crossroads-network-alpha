# V384 — seasonal market, gate and marina repairs

The market no longer draws its baked summer ground/building image over the town. Its live shop and two booth sprites follow the season; the existing connected town paths and ground remain visible in all four seasons.

Two lamps flank the North Gate, with visible fixtures and matching night-light sources.

Winter town marina: remove all four boats and their loose mooring ropes; walk on safe inlet ice, retaining the main river barrier. The ice uses the river ice texture and tint with explicitly repeating UVs. A real Marina Ice Hole replaces the ordinary cast location; the same species, catch tables and progression apply. Thawing cancels winter casts and returns a player standing in the inlet to the dock.

Oldwater Bay/Outback Cabin and all five Tidecross buildings plus bait/expedition kiosks were checked through their live winter renderers and native game captures; existing V382/V383 authored snowy roofs, sills, dormant plants and winter shop art are retained. Summer art restores outside winter. Ocean expedition ships remain at the saltwater port; the removed boats are the frozen town river marina boats.

Validation: native Godot 4.7.2 software OpenGL, all four market seasons, gate at night, marina winter/summer and bay/harbour winter captures. Automated checks cover winter inlet walking, unsafe main river, four winter boats hidden, retained fishing pool, actual nearest ice-hole interaction, winter cast validity, thaw relocation and warm-season restoration. No live Render deployment or physical mobile playtest performed.

Protocol 11, ownership epoch 4 and database/save formats unchanged. Three complete packages retain all V383 source/art and use the established source-based server Docker layout. Individual deployment files remain below 100 MB; web pack parts are <=32 MiB.
