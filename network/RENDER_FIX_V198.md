# Render startup repair — v198

The original v198 server update omitted two required files. This caused Godot to report `Static function begin() not found` and `Too many arguments for setup()` when Render started the server.

1. Extract `Crossroads_v198_Render_Fix.zip`.
2. In the existing GitHub server repository, replace `network/town_return.gd` and `network/leave_link.gd` with the files in this ZIP. Keep the `network` folder at the repository root, alongside `network_service`, `scripts`, and `project.godot`.
3. Commit both files, then deploy the latest commit on the existing Render service.
4. Confirm startup reports `V198-shatterfloor` and the service becomes healthy.

This is a two-file repair for a repository already updated with v198. No new Render service, database reset, migration, environment/key changes, or itch.io re-upload is needed for this repair. Do not remove files from the repository.

The original `Crossroads_v198_Server_Update.zip` has also been replaced with a complete runtime package for future updates. The existing v198 web and editable downloads are unchanged.
