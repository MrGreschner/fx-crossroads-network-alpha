# Crossroads: Realms Beyond — V244 handoff

Current authoritative release: **V244-street-details**. Step 4 (street details, consistency and performance review) is complete in the supplied packages. V241 grand landmarks, V242 shops/public buildings and V243 homes/vegetation are retained. No deployment has been performed.

## Authoritative packages

- `Crossroads_v244_Editable.zip`: complete Godot project under `Crossroads_Realms_Beyond/`, including new originals, references, prompts, preparation scripts, QA and evidence.
- `Crossroads_v244_Server_Update.zip`: complete server project. Preserve the current environment, secrets and persistent data when installing.
- `Crossroads_v244_Web.zip`: complete static Web build; install after restarting the V244 server.
- `V244_Previews.zip`: 144 full-size native packaged-runtime captures, day/night review boards, selected browser captures and production Web boot.

Shipped production PCK SHA-256: `7ca31f9c97a985f1a26de5123b8008bbba1a756840ab750e48f41b6fbd07c60a`.

Read `UPDATE_V244.md`, `ART_SOURCES_V244.md`, `VALIDATION_V244.md` and `RELEASE_INTEGRITY_V244.json`. Modified runtime resources are byte-identical across Editable, Server Update and Web PCK. QA fixtures are separate from production Web; their copies of every production resource are verified identical.

## Preserve in future work

All four town-art batches are now represented in V244. Continue from this Editable package rather than V241, incomplete V242, or an earlier handoff. Keep each building and object recognisable; use soft coloured edges, matte shading, readable clusters and neutral character poses. Preserve entrances, collisions, scale, services, NPC routes, curriculum, progression and economy. Street art is static and shared; do not replace it with per-object shaders, particles or simulation nodes.

The complete navigation contract matches V243 at 32,388 sampled positions, 315 resident schedule states and 288 patrol states. State/constant declarations and non-renderer functions are preserved. Four cache PNGs have local substitutions only; pixel masks and baseline pages are supplied. All approved building, home and vegetation artwork remains intact. Two older sign-placement issues (watermill and Mistglass Spire) are corrected by text rectangles only.

## Verification and limits

Godot 4.5.1 native Compatibility renderer, 1280×720; source and packaged-runtime checks, day/night/state captures, fresh server import and dedicated-server compilation. Chromium headless/WebGL2 rendered the production runtime through a separate QA fixture and booted the unmodified production Web build to its main menu. The browser fixture checks four day/night camera states and clear approaches. Physical school hardware and live multiplayer/account connectivity were not tested. Local static preview cannot satisfy account-service probes because no backend is deployed there.

Native QA inherits the existing ObjectDB/three-resource cleanup warning at shutdown, after successful checks. No final in-session script errors were observed. Installation/deployment remains a separate action; none was performed.
