# V385 packages

Web: extract the complete Web ZIP contents for your web deployment. Keep index.html, engine files and pack/ together.
Full server: extract Server_Project contents into the server repository root containing Dockerfile.network and project.godot. Preserve your .git directory and private settings. This is the complete source/art archive, not a PCK-only build.
Editable: extract and open Crossroads_Realms_Beyond/project.godot in Godot. All source and artwork included.
Server update: requires V384 already in the server repository. Extract its contents directly into that root, replace matching files, commit/push with GitHub Desktop. No scripts to run and no deletions. Full V385 server archive remains your standalone offline backup.

Do not commit ZIP files themselves. All individual deployed files are below100MB; web pack parts<=32MiB. Protocol11, database format and earned ownership epoch4 unchanged. Deploy the matching full server or update so the server has the revised journey catalogue and validation rules too.
