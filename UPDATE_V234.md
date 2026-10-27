# Crossroads V234 — Loading cast and opening-scene corrections

## Changes
- Enlarged loading-screen guard, foreman and working Rams to read consistently beside the portal and trolley. Kept the mason's feet on the work platform.
- Rebuilt the stone trolley with timber boards, iron straps, individual stone blocks, hubs and spokes. Added a braced work platform and small construction supplies. Removed duplicate guard spear/shield overlays; the guard uses a stationary pose.
- Bramble now charges, winds up and swipes first. The Young Ram recoils, counters, and follows Bramble through the portal.
- The Ram keeps alternating its feet until its portal fade finishes; the chase no longer switches abruptly to idle. Removed the added chase bounce and reduced the upward slide while entering.
- Preserved the fixed camera, creek/fish/cat sequence, portal artwork, title timing, all gameplay and account/server data.

## Validation
- 3,958 native cinematic checks passed, including attack order, alternating entrance frames, a stable chase baseline and activation timing.
- 49,522 browser/native timeline value comparisons passed over the complete 22.5-second scene.
- Loading SVG structure validated and rendered for a proportion/layout review. Full native intro rendered to inspect the action and portal entrance.
- Browser scripts syntax checked. A live browser playback test was unavailable in this environment; please test the packaged Web build on your usual devices before publishing.
- Release ZIP integrity and unchanged gameplay/backend comparisons verified during packaging.

## Install
Upload the Server Update first, then replace the Web build. The Editable package contains the complete project. This update has not been deployed.
