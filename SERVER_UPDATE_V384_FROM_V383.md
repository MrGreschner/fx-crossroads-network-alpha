# Server update V383 → V384

Requires the complete V383 server project already in your GitHub Desktop repository. This is an update, not a standalone server.

1. Extract this ZIP somewhere convenient.
2. Copy ALL extracted contents directly into your existing server repository root (the folder containing Dockerfile.network and project.godot). Replace matching files. Do not place them inside an extra nested folder.
3. In GitHub Desktop, review changes, commit as V384, and Push origin. Render can deploy that commit through your existing deployment setup.

No files need deleting. No scripts need running. No database migration or save reset is required. Keep your existing .git directory and private environment settings. Do not commit this ZIP itself.

Contains every changed/new project file between the verified full V383 and V384 server archives. Applying these changes reconstructs every V384 project file; unchanged artwork is already present in V383. The two extra update documents are harmless metadata. The full V384 server ZIP remains your independent offline archive. Protocol 11 and ownership epoch 4 are unchanged.

Future releases should include four ZIPs: complete Web, complete Server_Project, complete Editable, and a clearly based Server_Update. If files ever require deletion, list them explicitly.
