# Install the T4.9.1 server using the GitHub website

The four updated files are correct. The October 15 audit found them uploaded at the repository root, while the runtime files in their original folders were unchanged. The manifest and this guide are documentation; uploading them does not update running code.

Extract this ZIP on your computer first. Do not upload the ZIP itself.

For the least confusing method, update one folder at a time on the GitHub website, on the branch Render deploys:

1. Open the repository's **scripts** folder. Choose **Add file > Upload files**. From the extracted patch's scripts folder, upload **morrow_combat.gd** and **v46_heroes.gd**. Commit the changes.
2. Open the repository's **network** folder. Choose **Add file > Upload files**. From the extracted patch's network folder, upload **server.gd**. Commit.
3. Open the repository's **network_service** folder. Choose **Add file > Upload files**. From the extracted patch's network_service folder, upload **gateway.mjs**. Commit.

The resulting paths must be exactly:

- scripts/morrow_combat.gd
- scripts/v46_heroes.gd
- network/server.gd
- network_service/gateway.mjs

The extra copies at the repository root do not replace these files. Leave cleanup until the server is confirmed working. Do not change only a version label: all four actual patch files are required.

Open network_service/gateway.mjs in GitHub and search for T4.9.1. Open network/server.gd and check its welcome packet also says T4.9.1. Then in Render select Manual Deploy > Deploy latest commit for the game service. Wait for a successful deployment.

Open https://fx-crossroads-network-alpha.onrender.com/health . It must show ready:true, build:T4.9.1 and protocol:3. If GitHub contains the correct folder files but health remains T4.8, check Render's connected repository, branch and latest successful deployment commit. A failed deploy can leave the previous version running.

Client T4.9 works with this server; T4.10 is the new optional client update. A new itch upload alone cannot apply this server correction.
