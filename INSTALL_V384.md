# V384 complete packages

- Web: extract the entire Crossroads_v384_Web.zip contents into the web deployment/upload folder. Keep index.html, engine files and the complete pack directory together. Data chunks are required; do not rename or combine them.
- Server_Project: extract Crossroads_v384_Server_Project.zip directly into the root of your existing server repository (where Dockerfile.network and project.godot belong), replacing matching files. Keep your existing .git directory and private environment settings. This contains the full source/art project and both established service directories; it is not a PCK-only package. Review changes in GitHub Desktop, commit and push. Never commit the downloaded ZIP itself.
- Editable: extract Crossroads_v384_Editable.zip, then import Crossroads_Realms_Beyond/project.godot into Godot. Editor import regenerates its cache. All established art, code and source/deployment files are included, together with the V382/V383 winter art sources.

This updates seasonal town presentation and local hub ice traversal. Protocol 11 and ownership epoch 4 remain unchanged. No database migration or progress reset is required. An authority compatible with V381 remains compatible with Web V384; a matching full server package is provided for your complete backup and optional deployment.

Retain the V383 packages as rollback. These complete packages do not depend on another version archive. All individual deployed files are below 100 MB; web data chunks are no larger than 32 MiB. The downloadable archives themselves are larger than 100 MB because they contain the full game. Extract before committing/uploading.
