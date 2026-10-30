# Crossroads: Realms Beyond — V243 handoff

Current authoritative release: **V243-homes-vegetation**. Step 3 (homes and vegetation) is complete. V242 shops/public buildings and V241 grand landmarks are retained. No deployment has been performed.

## Authoritative downloads

- `Crossroads_v243_Editable.zip`: complete project under `Crossroads_Realms_Beyond/`; includes accepted art originals, references, prompts, preparation script, layout record, QA and evidence.
- `Crossroads_v243_Server_Update.zip`: complete server project; preserve your environment, secrets and persistent user data when installing.
- `Crossroads_v243_Web.zip`: complete static Web build with the V243 PCK; install after restarting the V243 server.
- `V243_Previews.zip`: forty-one actual native in-game screenshots, including eighteen areas by day and night, apple knock, watered garden and three canopy phases; plus four labelled overview boards.

Read `UPDATE_V243.md`, `ART_SOURCES_V243.md`, `VALIDATION_V243.md` and `RELEASE_INTEGRITY_V243.json`. The integrity record identifies the shipped PCK hash and archive checks. The three runtime packages have byte-identical modified resources. Source and packaged-runtime checks passed; original world/navigation/service data and resident schedules match V242.

## Continue with step 4

Street details remain the next batch: benches, fences, signs, carts, crates, bridges and remaining decorations, followed by town-wide consistency and performance review. Audit each object's current location, footprint and interactions before editing it. Keep each object's own design, soft coloured edges, matte shading and readable pixel clusters. Preserve all entrances, collisions, services, NPC routes, curriculum, progression and economy. Use restrained movement and efficient rendering for school computers.

Do not restart from V241 or an earlier incomplete V242 file. Use the V243 Editable archive above. Keep the V241/V242 building art and V243 six-home identities and tree species distinct. Source preservation and layout records are available in `tools/verification243/` and `tools/town243_layout.json`.

## Environment and validation limits

Godot 4.5.1 stable, native Compatibility/OpenGL renderer, 1280×720 captures with Mesa llvmpipe. Browser execution and physical school-device performance are untested here; do not represent the software-renderer measurements as school-device frame rates. The inherited QA fixture logs an ObjectDB/three-resource shutdown warning after successful runs; there were no in-session script or rendering errors in the final checks. No external server or website was deployed.
