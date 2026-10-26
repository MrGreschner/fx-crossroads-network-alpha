# Crossroads: Realms Beyond — V214

## Hero polish
Ten heroes now use the soft coloured edges, matte shading, coarse square-pixel clusters and neutral front-facing poses of V207/V208:
Tumblebrew, Rook Ironhand, Alderjaw, Iris Chalkbinder, Bolt Ironcore, Cloudloom, Cairnheart, Caelum Mirrorwright, Dustdevil and Merrymask.

Each has six small transparent poses: idle, movement A, movement B, primary, secondary and special. Individual species, palette, outfit, silhouette and equipment are preserved. Rook and Iris have the requested darker skin tones. Cloudloom retains wizard robes, Cairnheart is recognisably a badger, and the vacuum, teapot, robot and puppet retain their distinct anatomy. Merrymask's movement frames alternate legs.

Display sizes are calibrated against Young Ram, retaining normal adult proportions and shorter, broader animal/object bodies. All V213 size corrections remain in place. Frame preparation follows actual sheet gutters and the body foot anchor, avoiding scale/alignment errors from loose particles.

## Reed of Silverfall walking fix
Movement B had its main body 11 pixels above and 7 pixels left of the other walking frames. Fourteen isolated pixels below the body hid the mismatch in the full image bounds. Those pixels are removed and the body is aligned to idle/movement A, eliminating the apparent hop. His capybara design, abilities, size and movement physics are unchanged.

## Validation
3,606 automated checks passed: 3,590 hero/frame/stat/UI/cave checks and 16 networking checks. Hero/frame, accepted-action, stat, scale, portrait, layout, import, Reed-alignment and cave checks passed. Networking regression and dedicated authority startup are checked. Native visual checks cover all new poses, Reed and the Hall at normal/compact resolutions. The test fixtures retain the pre-existing resource-in-use teardown warnings. Browser and real-device playtesting remain.

## Deployment
Deploy Crossroads_v214_Server_Update.zip to Render first, then Crossroads_v214_Web.zip to itch.io. Crossroads_v214_Editable.zip retains source artwork, preparation tools, prompts and QA. No live deployment has been performed. Preserve existing accounts, database, records, saves, keys and environment variables. No migration or record reset is required.
