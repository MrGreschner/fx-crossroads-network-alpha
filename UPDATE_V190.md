# Crossroads v190 — private numeric game IDs

## Account identification

Accounts receive a unique, randomly generated six-digit game ID, for example **004821**. Leading zeroes are preserved. The service checks uniqueness in PostgreSQL and retries a collision. The ID stays the same across sign-ins and school-role changes.

No surname fragments, first initials, last initials, real names or official school student numbers are requested by the school-identification flow. Existing public game usernames and passwords remain the sign-in method. Students should keep usernames fictional and avoid real names.

The private game ID appears in the player's account window and the protected administrator account list. Administrators can search by the exact six-digit ID or by game username. The ID is not published to community records or included in downloadable profiles. IDs are not passwords and must not be accepted as login credentials.

Assigning Student or Teacher enables the existing Academy permissions without asking for any additional identification. Keep a student-to-game-ID list only in your school's approved records system. A linkable random ID is pseudonymous, not a guarantee of anonymity or school privacy approval.

## Migration

At server startup, the database adds the ID columns/index and removes the old encrypted identification value from live account rows. Accounts, password hashes, saves and save history are preserved. Old initials-based payloads are rejected by the retired identification endpoint. Existing accounts receive an ID at their next authenticated account lookup or administrator listing. Deploy the updated server and web game together.

This cannot erase older copies in hosting-provider backups or previously downloaded files. Those must be handled under the applicable retention policy. No production database or hosting settings were changed while preparing this release.

## Installation

1. Upgrade the **existing Render Postgres database**, rather than deleting/recreating it. The $6/month compute option is a reasonable starting point for the current pilot; storage is billed separately. Monitor CPU, memory, disk use and request latency. Reports retain 30 days of data and cloud accounts keep ten save revisions, so growth depends on activity and save sizes.
2. Upload **Crossroads_v190_Server.zip** contents at the root of the existing GitHub server repository and deploy Render. Keep DATABASE_URL, CLOUD_SAVE_KEY and the administrator/report secrets unchanged. Changing the encryption key would prevent reading existing encrypted saves.
3. Upload **Crossroads_v190_Web.zip** as the playable HTML game on the existing itch.io page. Keep the established page URL and browser site data. **Crossroads_v190_Editable.zip** is the Godot editing/debug project.
4. Sign in, open the account window and note the private numeric ID. In the administrator account page, search that number and assign the school role if appropriate. Public game usernames remain unchanged.

This release includes the v189 lantern, Trail Boots and starter-boss changes. It does not fix the unconfirmed v186 grey-screen crash or certify the hosting arrangement for student records.
