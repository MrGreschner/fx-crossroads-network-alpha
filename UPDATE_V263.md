# Crossroads: Realms Beyond — V263

Completed update: textured town pond bank and Descent depth 50.5 mine refuge. Base: the authoritative completed V262 Editable project (Library libfile_8653ae710f008191b6ae224f6bd6f814). Godot 4.5.1; release V263-mine-refuge; protocol 11 / report 3 unchanged. Nothing deployed.

## What changed
- Pond: soft, damp textured bank from the existing marina/river shoreline material. Original 48-point water boundary, animated water, fish, lily pads, access and town collision geometry preserved. Cached 495×345 overlay; no new shader or per-frame shoreline generation.
- Descent: defeating floor 50 triggers the usual fall into depth 50.5, a 1280×960 timber-supported mine chamber with four torches, healing well, merchant and ladder hatch. No enemies or attacks. Combat clock, oil consumption and downed bleed-out pause here. The well heals living heroes within 140 world pixels at exactly 10 HP/second, capped at each hero's maximum; it does not revive.
- Merchant: E within 150 pixels opens the normal CC equipment/consumable catalogue, with existing prices, discounts and inventory capacity. Server validates purchases, distance and life state. No Battleground-only items.
- Ladder: E within 100 pixels starts floor 51 in solo. In co-op every living player must be nearby and ready; walking away clears readiness. Downed players use the existing manual rescue. HP, CC, items and Descent upgrades carry through. Refuge occurs once per run, between 50 and 51. It is not an extra credited combat floor: best/completed floor remains 50 until 51 is beaten.
- Same-number floor transitions replicate the refuge geometry in both existing client receivers; authoritative exit restores ordinary level-51 geometry. Optional rest263 snapshot field; matched V263 server/client required for this feature.

## Verification and limits
Focused native and Chromium WebGL checks cover actual floor-50 guardian defeat; transition in/out; exact healing at 10/30/60/120 updates per second; maximum HP; no healing outside the well or for downed heroes; no empty-room auto-advance, attack or damage; paused oil/time; real E merchant interaction; item price and distance rejection; generic and dedicated-client snapshot receivers; solo exit; co-op readiness and distinct spawn points; no repeated refuge; fresh-run reset. Existing 4,350-check Descent regression passes. Pond checks preserve all 48 original water vertices and verify daytime/nighttime civil times. Production Web smoke boot and frozen native/browser visual captures included in evidence.

This is deterministic local fixture and state-receiver verification, not a public multiplayer deployment or a school-device FPS benchmark. Existing inherited Godot shutdown ObjectDB/resource warnings persist in the fixture; no added texture leak remains. Runtime artwork reuses existing atlases plus two small cached PNGs (~990 KB decoded RGBA), with one bank draw and one room-light overlay. No dynamic light nodes, full-screen shader or runtime texture synthesis added.

## Install / continue
Back up the current deployed build. Apply Server Update first, then matching Web. Do not mix V262 and V263 processes while testing the half-floor. Web zip has index.html at root. Server Update preserves the existing server/network_service layout; follow its prior deployment instructions. Editable.tar.xz is the complete project with every prior source file, previous releases' tools/evidence and the new V263 sources. Open project.godot in Godot 4.5.1 and allow import before export.

## Important files
scripts/descent_rest263.gd: refuge rendering, healing, readiness, merchant UI. scripts/descent_journey.gd: transition/replication integration. scripts/pond_bank263.gd and assets/rest263: shoreline/light mask. scripts/arcade.gd and network/arena.gd, network/server.gd: authoritative gameplay/input/state integration. qa/v263_check.gd and qa/v263_pond.gd: reproducible focused fixtures. tools/release263 and qa/evidence263: production preparation and evidence.

Previous V262 Battlegrounds, V261 Arena, V260 North Gate, V259 boss/UI fixes and all earlier project features remain carried forward. No content/scenes balance tables or existing town layout were changed. New geometry applies only inside the refuge.
