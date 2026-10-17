# Crossroads: Realms Beyond — v177

This update fixes the mobile HUD and restores a graphical party lobby over the T4 authoritative multiplayer transport. It includes the v176.1 animated town portal and v176.2 single animated introduction. Nothing has been deployed automatically.

## What changed

- Food, three item slots and two relic slots now form a single row directly below the combat header, on desktop and mobile. Rotation keeps the same logical anchor. Realm objectives move below it.
- The town welcome checklist is a compact two-line card directly below the town HUD. It disappears after eight visible seconds, measured by the real clock so a slow device cannot stretch it indefinitely. Time spent behind a menu or the intro does not consume its reading time. The checklist remains accessible from the Adventure board. Removed the separate startup welcome text.
- The Character Hall label is raised above the courtyard elder tree's canopy. The tree and its collision stay in their existing position.
- The party lobby uses real animated character sprites, player names and selected heroes. Five adventure choices, a hero grid, room-code joining, room capacity, public/private visibility, live party members and Start match remain together.
- Students no longer enter a server address. The exported client uses `wss://fx-crossroads-network-alpha.onrender.com`, the existing paid T4 service. That service was reachable as V176-preview / protocol 10 during this work.
- Public-room discovery is implemented by the T4 server. Only explicitly public, unstarted, non-full parties with a connected host appear. Private room codes, profile data and reconnect tokens are not exposed in that list. Refresh is manual; browsing does not allocate a match.
- Leaving a match restores Host / Join in the graphical lobby. Back to town is a separate lobby action. No browser refresh is required to host again.
- Client, server, downloaded reports and reporting dashboard labels now identify V177-preview. Protocol remains 10; database schemas and saved-profile locations remain unchanged.

## Multiplayer capacities

| Mode | Player capacity |
| --- | --- |
| Gladiator Arena | 2, 4 or 8 |
| Gate Defence | 2 or 4 |
| Ram's Descent | 2 or 4 |
| Realm co-op, including Between and Overcharge | 2 |
| Battlegrounds | 3v3 or 4v4 |

The existing measured server capacity limits still apply. This update does not increase them or change T4 combat prediction, reconciliation, interpolation or hit authority. Attunement remains a solo challenge.

## Upload order

1. Extract `Crossroads_v177_Server.zip`. Replace the matching contents of the GitHub repository connected to the existing alpha/T4 Render game service. Upload the contents, not the ZIP itself. The repository root should contain `Dockerfile.network`, `project.godot`, `network/`, `network_service/` and the other supplied folders. Include the new `network/party_lobby.gd` and `network/party_stage.gd`; using the complete package avoids missing dependencies.
2. Deploy that repository on the same Render service. Keep the paid instance, database, credentials, environment variables and hostname.
3. Open `https://fx-crossroads-network-alpha.onrender.com/health`. Confirm `ready: true`, `build: V177-preview`, `protocol: 10` and `public_rooms: true`.
4. Replace the HTML upload on the Crossroads: Realms Beyond playtest itch.io page with `Crossroads_v177_Web.zip`, keeping it marked playable in the browser. Upload this ZIP without extracting it. Refresh existing browser tabs.
5. Keep the old public FX Crossroads build unchanged while validating this playtest.

This release needs the new server for public-room discovery. Existing V176 protocol-10 servers can still host/join by code, but cannot provide the new room list until updated. No database migration or account creation is involved.

For local Godot use, extract `Crossroads_v177_Editable.zip` and open its `project.godot` with Godot 4.5.1 / the compatible 4.5 series.

## Verification

- Native scene checks: five mode controls, configured/hidden endpoint, compact timed welcome and loadout anchor.
- Packed web check: landscape and portrait rotation, actual eight-second welcome timeout, room browser, phone-sized host and desktop guest, live hero selection, match start, authoritative snapshots and return to the lobby.
- Public-room privacy checks: private rooms stay undiscoverable; active matches are removed from discovery.
- Real WebSocket authority start checks: eight-player Arena, four-player Gate Defence, four-player Ram's Descent, two-player realm co-op and eight-player Battlegrounds all received start packets and snapshots.
- Between and Overcharge co-op checks retained host-selected reach, personal entry costs, reconnect without duplicate cost and successful shared Between extraction.
- Final archives receive CRC/structure validation. Server package contents are checked against their hashes and imported separately.

Automated virtual clients are not evidence of school-network or Chromebook FPS. The next student test should check the visible lobby, phone typing, rotated HUD and a real multi-device match. Downloaded student profiles remain the current persistence system.
